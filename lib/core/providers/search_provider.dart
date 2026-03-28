import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../data/models.dart';

class SearchResult {
  final String title;
  final String subtitle;
  final LatLng position;

  SearchResult({
    required this.title,
    required this.subtitle,
    required this.position,
  });
}

class SearchNotifier extends Notifier<AsyncValue<List<SearchResult>>> {
  Timer? _debounceTimer;
  int _requestId = 0; // guards against stale responses

  @override
  AsyncValue<List<SearchResult>> build() {
    ref.onDispose(() {
      _debounceTimer?.cancel();
    });
    return const AsyncValue.data([]);
  }

  /// Debounced search — waits 300ms after last keystroke before firing
  void search(String query) {
    _debounceTimer?.cancel();

    if (query.isEmpty || query.length < 3) {
      state = const AsyncValue.data([]);
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _executeSearch(query);
    });
  }

  Future<void> _executeSearch(String query) async {
    final currentRequestId = ++_requestId;
    state = const AsyncValue.loading();

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&addressdetails=1&limit=5&viewbox=85.7,20.2,85.9,20.4&bounded=1'
      );

      final response = await http.get(url, headers: {
        'User-Agent': 'VelocityTransitApp/1.0',
      });

      // Discard if a newer request has been fired
      if (currentRequestId != _requestId) return;

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final results = data.map((item) {
          final address = item['address'];
          final road = (address['road'] ?? address['suburb'] ?? address['city_district'] ?? address['neighbourhood'] ?? '') as String;
          final name = (item['display_name'] as String).split(',')[0];

          return SearchResult(
            title: name,
            subtitle: road,
            position: LatLng(
              double.parse(item['lat']),
              double.parse(item['lon']),
            ),
          );
        }).toList();
        state = AsyncValue.data(results);
      } else {
        state = AsyncValue.error('Search failed', StackTrace.current);
      }
    } catch (e, st) {
      if (currentRequestId != _requestId) return;
      state = AsyncValue.error(e, st);
    }
  }
}

final searchProvider = NotifierProvider<SearchNotifier, AsyncValue<List<SearchResult>>>(
  SearchNotifier.new,
);
