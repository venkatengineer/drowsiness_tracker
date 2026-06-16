import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api_config.dart';

class UserSession {
  final int id;
  final String username;

  UserSession({required this.id, required this.username});

  factory UserSession.fromJson(Map<String, dynamic> json) {
    return UserSession(
      id: int.parse(json['id'].toString()),
      username: json['username'] as String,
    );
  }
}

class AuthApi {
  AuthApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static UserSession? currentSession;

  Future<void> login({
    required String username,
    required String password,
  }) async {
    final responseBody = await _post('/auth/login', {'username': username, 'password': password});
    final decoded = jsonDecode(responseBody) as Map<String, dynamic>;
    final userJson = decoded['user'] as Map<String, dynamic>;
    currentSession = UserSession.fromJson(userJson);
  }

  Future<void> register({
    required String username,
    required String password,
    String? email,
    String? phoneNumber,
  }) async {
    final responseBody = await _post('/auth/register', {
      'username': username,
      'password': password,
      'email': email,
      'phone_number': phoneNumber,
    });
    final decoded = jsonDecode(responseBody) as Map<String, dynamic>;
    final userJson = decoded['user'] as Map<String, dynamic>;
    currentSession = UserSession.fromJson(userJson);
  }

  Future<Map<String, dynamic>> getUserDetails() async {
    final session = currentSession;
    if (session == null) {
      throw const AuthApiException('No active session.');
    }

    final responseBody = await _post('/users/details', {
      'username': session.username,
      'user_id': session.id,
    });

    final decoded = jsonDecode(responseBody);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    throw const AuthApiException('Invalid response from server.');
  }

  Future<void> saveOnboarding({
    required String fullName,
    required int age,
    required String gender,
    required String vehicleNumber,
    required String vehicleType,
    required String emergencyContactName,
    required String emergencyContactNumber,
    required int averageDailyDrivingHours,
  }) async {
    final session = currentSession;
    if (session == null) {
      throw const AuthApiException('No active session.');
    }

    await _post('/users/onboarding', {
      'user_id': session.id,
      'full_name': fullName,
      'age': age,
      'gender': gender,
      'vehicle_number': vehicleNumber,
      'vehicle_type': vehicleType,
      'emergency_contact_name': emergencyContactName,
      'emergency_contact_number': emergencyContactNumber,
      'average_daily_driving_hours': averageDailyDrivingHours,
    });
  }

  void logout() {
    currentSession = null;
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
      throw const AuthApiException(
        'Cannot reach backend. Check that the Python server is running.',
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.body;
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

