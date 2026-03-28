import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../data/models.dart';
import '../providers/auth_provider.dart';

class BackendApiService {
  BackendApiService({
    http.Client? client,
    AuthService? authService,
  }) : _client = client ?? http.Client(),
       _authService = authService ?? AuthService();

  final http.Client _client;
  final AuthService _authService;

  Future<List<TransitRoute>> fetchRoutes() async {
    final payload = await _getJson('/api/routes');
    final routes = (payload['routes'] as List<dynamic>? ?? const [])
        .map((route) {
          final map = Map<String, dynamic>.from(route);
          return TransitRoute.fromMap(map['id']?.toString() ?? '', map);
        })
        .toList();
    return routes;
  }

  Future<List<BusAssignment>> fetchActiveAssignments() async {
    final payload = await _getJson('/api/assignments/active');
    return (payload['assignments'] as List<dynamic>? ?? const [])
        .map((assignment) {
          final map = Map<String, dynamic>.from(assignment);
          return BusAssignment.fromMap(map['id']?.toString() ?? '', map);
        })
        .toList();
  }

  Future<BusAssignment?> fetchMyAssignment() async {
    final payload = await _getJson('/api/assignments/my');
    final assignment = payload['assignment'];
    if (assignment == null) return null;
    final map = Map<String, dynamic>.from(assignment);
    return BusAssignment.fromMap(map['id']?.toString() ?? '', map);
  }

  Future<Map<String, Map<String, dynamic>>> fetchBusesRaw() async {
    final payload = await _getJson('/api/buses');
    final items = (payload['buses'] as List<dynamic>? ?? const []);
    return {
      for (final item in items)
        (item['id']?.toString() ?? ''): Map<String, dynamic>.from(item),
    };
  }

  Future<List<LiveBusSnapshot>> fetchLivePositions() async {
    final payload = await _getJson('/api/tracking/live');
    return (payload['positions'] as List<dynamic>? ?? const [])
        .map((position) => LiveBusSnapshot.fromMap(Map<String, dynamic>.from(position)))
        .toList();
  }

  Future<List<TransitAlert>> fetchAlerts() async {
    try {
      final payload = await _getJson('/api/notifications/history');
      return (payload['alerts'] as List<dynamic>? ?? const [])
          .map((alert) {
            final map = Map<String, dynamic>.from(alert);
            return TransitAlert.fromMap(map['id']?.toString() ?? '', map);
          })
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> updateProfile({
    required String name,
    String? phone,
  }) async {
    final payload = <String, dynamic>{
      'name': name,
      'phone': phone,
    }..removeWhere((_, value) => value == null);

    await _patchJson('/api/users/me', payload);
  }

  Future<void> syncFcmToken({
    required String token,
    required AppRoleChoice role,
  }) async {
    await _postJson('/api/notifications/token', {
      'token': token,
      'role': role.name,
      'platform': 'flutter',
    });
  }

  Future<void> removeFcmToken(String token) async {
    await _deleteJson('/api/notifications/token', {'token': token});
  }

  Future<void> sendTripEvent({
    required String type,
    required String busId,
    required String busNumber,
    required String routeId,
    required String routeName,
    String? nextStop,
    int? etaMinutes,
  }) async {
    final payload = <String, dynamic>{
      'type': type,
      'busId': busId,
      'busNumber': busNumber,
      'routeId': routeId,
      'routeName': routeName,
      'nextStop': nextStop,
      'etaMinutes': etaMinutes,
    }..removeWhere((_, value) => value == null);

    await _postJson('/api/notifications/trip-event', payload);
  }

  Future<void> sendAdminNotification({
    required String title,
    required String body,
    String audience = 'all',
    String type = 'service_update',
    String? routeId,
    String? busId,
  }) async {
    final payload = <String, dynamic>{
      'title': title,
      'body': body,
      'audience': audience,
      'type': type,
      'routeId': routeId,
      'busId': busId,
    }..removeWhere((_, value) => value == null || value == '');

    await _postJson('/api/notifications/broadcast', payload);
  }

  Future<String> askCopilot({
    required String question,
    List<Map<String, String>> history = const [],
  }) async {
    final payload = await _postJson('/api/copilot/chat', {
      'question': question,
      'history': history,
    });
    final answer = payload['answer']?.toString().trim() ?? '';
    if (answer.isEmpty) {
      throw Exception('Copilot returned an empty response');
    }
    return answer;
  }

  Future<Map<String, dynamic>> _getJson(String path) async {
    final token = await _requireToken();
    final response = await _client.get(
      Uri.parse('${AppConfig.backendBaseUrl}$path'),
      headers: _headers(token),
    );
    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> _postJson(String path, Map<String, dynamic> body) async {
    final token = await _requireToken();
    final response = await _client.post(
      Uri.parse('${AppConfig.backendBaseUrl}$path'),
      headers: _headers(token),
      body: jsonEncode(body),
    );
    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> _patchJson(String path, Map<String, dynamic> body) async {
    final token = await _requireToken();
    final response = await _client.patch(
      Uri.parse('${AppConfig.backendBaseUrl}$path'),
      headers: _headers(token),
      body: jsonEncode(body),
    );
    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> _deleteJson(String path, Map<String, dynamic> body) async {
    final token = await _requireToken();
    final response = await _client.delete(
      Uri.parse('${AppConfig.backendBaseUrl}$path'),
      headers: _headers(token),
      body: jsonEncode(body),
    );
    return _decodeResponse(response);
  }

  Future<String> _requireToken() async {
    final token = await _authService.getIdToken();
    if (token == null) {
      throw Exception('Authentication token missing');
    }
    return token;
  }

  Map<String, String> _headers(String token) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    final body = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(body['error']?.toString() ?? 'Request failed');
    }
    return body;
  }
}
