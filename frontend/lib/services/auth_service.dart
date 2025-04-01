import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // For Android emulator, we use 10.0.2.2 to access host machine's localhost
  final String baseUrl = 'http://10.0.2.2:8000/api';
  static const timeout = Duration(seconds: 10); // Increased timeout

  // Get stored token
  Future<String?> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Set stored token
  Future<void> _setToken(String token) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  // Remove stored token
  Future<void> _removeToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  // Get auth headers
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Handle API response
  Map<String, dynamic>? _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      if (data['status'] == 'success') {
        return data;
      }
    }
    return null;
  }

  // Handle validation errors
  Map<String, dynamic>? _handleValidationError(http.Response response) {
    if (response.statusCode == 422) {
      final data = jsonDecode(response.body);
      if (data['errors'] != null) {
        return {
          'status': 'error',
          'errors': data['errors'],
          'message': data['message'] ?? 'Validation failed'
        };
      }
    }
    return null;
  }

  // Test API connection
  Future<bool> testConnection() async {
    try {
      print('Testing connection to: $baseUrl');
      // Use GET request to test if the API is accessible
      final response = await http.get(
        Uri.parse('$baseUrl/login'),
        headers: {
          "Accept": "application/json",
        },
      ).timeout(timeout);

      print('Connection test status: ${response.statusCode}');
      print('Connection test response: ${response.body}');

      // Consider it successful if we get any response (even 405 Method Not Allowed)
      // as this means the server is reachable
      return response.statusCode != 404;
    } catch (e) {
      print('Connection test error: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      print('Attempting login with email: $email');
      print('Using API URL: $baseUrl/login');

      final response = await http
          .post(
            Uri.parse('$baseUrl/login'),
            headers: {
              "Content-Type": "application/json",
              "Accept": "application/json",
            },
            body: jsonEncode({
              'email': email,
              'password': password,
            }),
          )
          .timeout(timeout);

      print('Login response status code: ${response.statusCode}');
      print('Login response body: ${response.body}');

      final data = _handleResponse(response);
      if (data != null && data['token'] != null) {
        await _setToken(data['token']);
        return data;
      }

      final validationError = _handleValidationError(response);
      if (validationError != null) {
        return validationError;
      }

      return null;
    } catch (e) {
      print('Login error details: $e');
      if (e is http.ClientException) {
        print('Connection error: ${e.message}');
      }
      return null;
    }
  }

  Future<Map<String, dynamic>?> register(
      String name, String email, String password) async {
    try {
      print('Attempting registration with email: $email');
      print('API URL: $baseUrl/register');

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
              'password_confirmation': password, // Added password confirmation
            }),
          )
          .timeout(timeout);

      print('Register response status code: ${response.statusCode}');
      print('Register response body: ${response.body}');

      final data = _handleResponse(response);
      if (data != null && data['token'] != null) {
        await _setToken(data['token']);
        return data;
      }

      final validationError = _handleValidationError(response);
      if (validationError != null) {
        return validationError;
      }

      return null;
    } catch (e) {
      print('Register error details: $e');
      if (e is http.ClientException) {
        print('Connection error: ${e.message}');
      }
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

      print('Get user response: ${response.body}');

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
      print('Get user error: $e');
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
      print('Logout error: $e');
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

      print('Send verification email response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'status': 'success',
          'message': data['message'] ?? 'Verification email sent successfully'
        };
      }
      return null;
    } catch (e) {
      print('Send verification email error: $e');
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

      print('Verify email response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'status': 'success',
          'message': data['message'] ?? 'Email verified successfully'
        };
      }
      return null;
    } catch (e) {
      print('Verify email error: $e');
      return null;
    }
  }
}
