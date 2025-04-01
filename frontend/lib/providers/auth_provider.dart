import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  String? _token;
  bool _isLoading = false;
  String? _error;
  Map<String, List<String>>? _validationErrors;
  DateTime? _emailVerifiedAt;

  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, List<String>>? get validationErrors => _validationErrors;
  bool get isAuthenticated => _token != null;
  bool get isEmailVerified => _emailVerifiedAt != null;
  DateTime? get emailVerifiedAt => _emailVerifiedAt;

  AuthProvider() {
    _loadToken();
  }

  void _clearErrors() {
    _error = null;
    _validationErrors = null;
    notifyListeners();
  }

  // Load token from SharedPreferences
  Future<void> _loadToken() async {
    _isLoading = true;
    _clearErrors();
    notifyListeners();

    try {
      final userData = await _authService.getUser();
      if (userData != null) {
        _token = userData['token'];
        if (userData['email_verified_at'] != null) {
          _emailVerifiedAt = DateTime.parse(userData['email_verified_at']);
        }
      } else {
        _token = null;
        _emailVerifiedAt = null;
      }
    } catch (e) {
      _token = null;
      _emailVerifiedAt = null;
      _error = 'Failed to load authentication state';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Save token to SharedPreferences
  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  // Remove token from SharedPreferences (for logout)
  Future<void> _removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _clearErrors();
    notifyListeners();

    try {
      final data = await _authService.login(email, password);
      if (data != null) {
        if (data['status'] == 'error') {
          _validationErrors = Map<String, List<String>>.from(data['errors']);
          _error = data['message'];
          return false;
        }
        _token = data['token'];
        await _saveToken(data['token']);
        notifyListeners();
        return true;
      }
      _error = 'Invalid credentials';
      return false;
    } catch (e) {
      _error = 'Failed to login';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register(String name, String email, String password) async {
    _isLoading = true;
    _clearErrors();
    notifyListeners();

    try {
      final data = await _authService.register(name, email, password);
      if (data != null) {
        if (data['status'] == 'error') {
          _validationErrors = Map<String, List<String>>.from(data['errors']);
          _error = data['message'];
          return false;
        }
        // Send verification email after successful registration
        await sendVerificationEmail();
        notifyListeners();
        return true;
      }
      _error = 'Registration failed';
      return false;
    } catch (e) {
      _error = 'Failed to register';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> logout() async {
    _isLoading = true;
    _clearErrors();
    notifyListeners();

    try {
      final success = await _authService.logout();
      if (success) {
        _token = null;
        await _removeToken();
        notifyListeners();
        return true;
      }
      _error = 'Failed to logout';
      return false;
    } catch (e) {
      _error = 'Failed to logout';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> refreshToken() async {
    try {
      final data = await _authService.refreshToken();
      if (data != null) {
        _token = data['token'];
        await _saveToken(data['token']);
        _clearErrors();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> sendVerificationEmail() async {
    _isLoading = true;
    _clearErrors();
    notifyListeners();

    try {
      final result = await _authService.sendVerificationEmail();
      if (result != null && result['status'] == 'success') {
        return true;
      }
      _error = 'Failed to send verification email';
      return false;
    } catch (e) {
      _error = 'Failed to send verification email';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> verifyEmail(String token) async {
    _isLoading = true;
    _clearErrors();
    notifyListeners();

    try {
      final result = await _authService.verifyEmail(token);
      if (result != null && result['status'] == 'success') {
        // Refresh user data to get updated email verification status
        await _loadToken();
        return true;
      }
      _error = 'Failed to verify email';
      return false;
    } catch (e) {
      _error = 'Failed to verify email';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _clearErrors();
  }
}
