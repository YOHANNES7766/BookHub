import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logging/logging.dart';

class AuthService {
  final String baseUrl = 'http://10.0.2.2:8000/api';
  static const timeout = Duration(seconds: 10);
  final Logger _logger = Logger('AuthService');

  // Token management
  Future<String?> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> _setToken(String token) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<void> _removeToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Map<String, dynamic>? _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      if (data['status'] == 'success') {
        return data;
      }
    }
    return null;
  }

  Map<String, dynamic>? _handleValidationError(http.Response response) {
    if (response.statusCode == 422) {
      final data = jsonDecode(response.body);
      if (data['errors'] != null) {
        return {
          'status': 'error',
          'errors': data['errors'],
          'message': data['message'] ?? 'Validation failed',
        };
      }
    }
    return null;
  }

  Future<bool> testConnection() async {
    try {
      _logger.info('Testing connection to: $baseUrl');
      final response = await http.get(
        Uri.parse('$baseUrl/login'),
        headers: {'Accept': 'application/json'},
      ).timeout(timeout);

      _logger.info('Connection status: ${response.statusCode}');
      _logger.fine('Connection body: ${response.body}');

      return response.statusCode != 404;
    } catch (e) {
      _logger.severe('Connection test failed: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      _logger.info('Attempting login with email: $email');

      final response = await http
          .post(
            Uri.parse('$baseUrl/login'),
            headers: {
              "Content-Type": "application/json",
              "Accept": "application/json",
            },
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(timeout);

      _logger.info('Login status: ${response.statusCode}');
      _logger.fine('Login body: ${response.body}');

      final data = _handleResponse(response);
      if (data != null && data['token'] != null) {
        await _setToken(data['token']);
        return data;
      }

      final validationError = _handleValidationError(response);
      if (validationError != null) return validationError;

      return null;
    } catch (e) {
      _logger.severe('Login error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> register(
      String name, String email, String password) async {
    try {
      _logger.info('Registering user with email: $email');

      final response = await http
          .post(
            Uri.parse('$baseUrl/register'),
            headers: {
              "Content-Type": "application/json",
              "Accept": "application/json",
            },
            body: jsonEncode({
              'name': name,
              'email': email,
              'password': password,
              'password_confirmation': password,
            }),
          )
          .timeout(timeout);

      _logger.info('Register status: ${response.statusCode}');
      _logger.fine('Register body: ${response.body}');

      final data = _handleResponse(response);
      if (data != null && data['token'] != null) {
        await _setToken(data['token']);
        return data;
      }

      final validationError = _handleValidationError(response);
      if (validationError != null) return validationError;

      return null;
    } catch (e) {
      _logger.severe('Registration error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getUser() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/user'),
            headers: await _getAuthHeaders(),
          )
          .timeout(timeout);

      _logger.fine('Get user body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'status': 'success',
          'token': await _getToken(),
          'user': data['user'] ?? {},
          'email_verified_at': data['user']?['email_verified_at'],
        };
      }
      return null;
    } catch (e) {
      _logger.severe('Get user error: $e');
      return null;
    }
  }

  Future<bool> logout() async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/logout'),
            headers: await _getAuthHeaders(),
          )
          .timeout(timeout);

      final data = _handleResponse(response);
      if (data != null) {
        await _removeToken();
        return true;
      }
      return false;
    } catch (e) {
      _logger.severe('Logout error: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> refreshToken() async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/refresh'),
            headers: await _getAuthHeaders(),
          )
          .timeout(timeout);

      final data = _handleResponse(response);
      if (data != null && data['token'] != null) {
        await _setToken(data['token']);
        return data;
      }
      return null;
    } catch (e) {
      _logger.severe('Refresh token error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> sendVerificationEmail() async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/email/verification-notification'),
            headers: await _getAuthHeaders(),
          )
          .timeout(timeout);

      _logger.fine('Verification email body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'status': 'success',
          'message': data['message'] ?? 'Verification email sent successfully',
        };
      }
      return null;
    } catch (e) {
      _logger.severe('Send verification email error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> verifyEmail(String token) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/email/verify/$token'),
            headers: await _getAuthHeaders(),
          )
          .timeout(timeout);

      _logger.fine('Verify email response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'status': 'success',
          'message': data['message'] ?? 'Email verified successfully',
        };
      }
      return null;
    } catch (e) {
      _logger.severe('Verify email error: $e');
      return null;
    }
  }
}
