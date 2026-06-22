import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api_config.dart';
import 'auth_api.dart';

class TripApi {
  TripApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<void> createTrip({
    required String startDestination,
    required String endDestination,
    double? startLatitude,
    double? startLongitude,
    double? endLatitude,
    double? endLongitude,
  }) async {
    final session = AuthApi.currentSession;
    await _post('/trips', {
      'user_id': session?.id,
      'start_destination': startDestination,
      'end_destination': endDestination,
      'start_latitude': startLatitude,
      'start_longitude': startLongitude,
      'end_latitude': endLatitude,
      'end_longitude': endLongitude,
    });
  }

  Future<String> _post(String path, Map<String, Object?> body) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');

    late http.Response response;
    try {
      response = await _client.post(
        uri,
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
    } catch (_) {
      throw const TripApiException(
        'Cannot reach backend. Check that the Python server is running.',
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.body;
    }

    throw TripApiException(_messageFrom(response));
  }

  String _messageFrom(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final message = decoded['message'];
        if (message is String && message.isNotEmpty) {
          return message;
        }
      }
    } catch (_) {
      // Fall through to generic error.
    }
    return 'Request failed with status ${response.statusCode}.';
  }
}

class TripApiException implements Exception {
  const TripApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
