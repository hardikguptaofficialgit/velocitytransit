import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../data/models.dart';
import '../data/simulation_data.dart';

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
    final trimmedQuery = query.trim();
    final localResults = _localResults(trimmedQuery);

    if (trimmedQuery.isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }

    if (trimmedQuery.length < 3) {
      state = AsyncValue.data(localResults);
      return;
    }

    state = const AsyncValue.loading();
    
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(trimmedQuery)}&format=json&addressdetails=1&limit=5&viewbox=85.7,20.2,85.9,20.4&bounded=1'
      );

      final response = await http.get(url, headers: {
        'User-Agent': 'VelocityTransitApp/1.0',
      }).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final remoteResults = data.map<SearchResult>((item) {
          final address = item['address'] as Map<String, dynamic>? ?? const {};
          final road = (address['road'] ??
                  address['suburb'] ??
                  address['city_district'] ??
                  address['neighbourhood'] ??
                  address['city'] ??
                  '') as String;
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
        state = AsyncValue.data(_mergeResults(localResults, remoteResults));
      } else {
        state = localResults.isNotEmpty
            ? AsyncValue.data(localResults)
            : AsyncValue.error('Search failed', StackTrace.current);
      }
    } catch (e, st) {
      state = localResults.isNotEmpty
          ? AsyncValue.data(localResults)
          : AsyncValue.error(e, st);
    }
  }

  List<SearchResult> _localResults(String query) {
    final normalized = query.toLowerCase();
    final stopMatches = <SearchResult>[];

    for (final route in SimulationData.routes) {
      if (route.name.toLowerCase().contains(normalized) ||
          route.shortName.toLowerCase().contains(normalized)) {
        stopMatches.add(
          SearchResult(
            title: route.name,
            subtitle: 'Route ${route.shortName} · ${route.stops.length} stops',
            position: route.stops.first.position,
          ),
        );
      }

      for (final stop in route.stops) {
        if (stop.name.toLowerCase().contains(normalized)) {
          stopMatches.add(
            SearchResult(
              title: stop.name,
              subtitle: route.name,
              position: stop.position,
            ),
          );
        }
      }
    }

    return _dedupe(stopMatches).take(6).toList();
  }

  List<SearchResult> _mergeResults(
    List<SearchResult> localResults,
    List<SearchResult> remoteResults,
  ) {
    return _dedupe([...localResults, ...remoteResults]).take(6).toList();
  }

  List<SearchResult> _dedupe(List<SearchResult> results) {
    final seen = <String>{};
    final filtered = <SearchResult>[];
    for (final result in results) {
      final key = '${result.title}|${result.subtitle}'.toLowerCase();
      if (seen.add(key)) {
        filtered.add(result);
      }
    }
    return filtered;
  }
}

final searchProvider = NotifierProvider<SearchNotifier, AsyncValue<List<SearchResult>>>(
  SearchNotifier.new,
);
