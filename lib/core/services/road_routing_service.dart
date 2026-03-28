import 'dart:convert';

import 'package:http/http.dart' as http;

import '../data/models.dart';

class RoadRoutingService {
  const RoadRoutingService();

  static const _baseUrl = 'https://router.project-osrm.org/route/v1/driving';

  Future<List<LatLng>> fetchRoutePath(List<LatLng> waypoints) async {
    if (waypoints.length < 2) return waypoints;

    final coordinates = waypoints
        .map(
          (point) =>
              '${point.longitude.toStringAsFixed(6)},${point.latitude.toStringAsFixed(6)}',
        )
        .join(';');

    final uri = Uri.parse(
      '$_baseUrl/$coordinates?overview=full&geometries=geojson&steps=false',
    );

    final response = await http.get(uri).timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) {
      throw Exception('Routing API failed with ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final routes = decoded['routes'] as List<dynamic>? ?? const [];
    if (routes.isEmpty) {
      throw Exception('Routing API returned no routes');
    }

    final geometry = routes.first['geometry'] as Map<String, dynamic>? ?? {};
    final coordinatesList =
        geometry['coordinates'] as List<dynamic>? ?? const [];
    if (coordinatesList.isEmpty) {
      throw Exception('Routing geometry is empty');
    }

    return coordinatesList
        .whereType<List<dynamic>>()
        .where((pair) => pair.length >= 2)
        .map(
          (pair) =>
              LatLng((pair[1] as num).toDouble(), (pair[0] as num).toDouble()),
        )
        .toList();
  }
}
