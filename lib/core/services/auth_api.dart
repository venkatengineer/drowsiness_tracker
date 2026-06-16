import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api_config.dart';

class AuthApi {
  AuthApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<void> login({
    required String username,
    required String password,
  }) async {
    await _post('/auth/login', {'username': username, 'password': password});
  }

  Future<void> register({
    required String username,
    required String password,
    String? email,
    String? phoneNumber,
  }) async {
    await _post('/auth/register', {
      'username': username,
      'password': password,
      'email': email,
      'phone_number': phoneNumber,
    });
  }

  Future<void> _post(String path, Map<String, Object?> body) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');

    late http.Response response;
    try {
      response = await _client.post(
        uri,
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
    } catch (_) {
      throw const AuthApiException(
        'Cannot reach backend. Check that the Python server is running.',
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    throw AuthApiException(_messageFrom(response));
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

class AuthApiException implements Exception {
  const AuthApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
