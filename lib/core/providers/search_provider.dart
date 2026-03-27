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
  @override
  AsyncValue<List<SearchResult>> build() {
    return const AsyncValue.data([]);
  }

  Future<void> search(String query) async {
    if (query.isEmpty || query.length < 3) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();
    
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&addressdetails=1&limit=5&viewbox=85.7,20.2,85.9,20.4&bounded=1'
      );

      final response = await http.get(url, headers: {
        'User-Agent': 'VelocityTransitApp/1.0',
      });

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
      state = AsyncValue.error(e, st);
    }
  }
}

final searchProvider = NotifierProvider<SearchNotifier, AsyncValue<List<SearchResult>>>(
  SearchNotifier.new,
);
