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

  String? get firstValidationError {
    if (_validationErrors != null && _validationErrors!.isNotEmpty) {
      return _validationErrors!.values.first.first;
    }
    return null;
  }

  Future<void> _loadToken() async {
    _isLoading = true;
    _clearErrors();
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString('auth_token');

      if (savedToken != null) {
        _token = savedToken;

        final userData = await _authService.getUser();
        if (userData != null && userData['email_verified_at'] != null) {
          _emailVerifiedAt = DateTime.parse(userData['email_verified_at']);
        }
      } else {
        _token = null;
        _emailVerifiedAt = null;
      }
    } catch (e) {
      debugPrint('Load token error: $e');
      _token = null;
      _emailVerifiedAt = null;
      _error = 'Failed to load authentication state';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<void> _removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token'); // Or prefs.clear() if you store more
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
        await refreshUserData();
        return true;
      }
      _error = 'Invalid credentials';
      return false;
    } catch (e) {
      debugPrint('Login error: $e');
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
        await sendVerificationEmail();
        return true;
      }
      _error = 'Registration failed';
      return false;
    } catch (e) {
      debugPrint('Register error: $e');
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
        _emailVerifiedAt = null;
        await _removeToken();
        return true;
      }
      _error = 'Failed to logout';
      return false;
    } catch (e) {
      debugPrint('Logout error: $e');
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
      debugPrint('Refresh token error: $e');
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
      debugPrint('Send verification email error: $e');
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
        await updateEmailVerificationStatus();
        return true;
      }
      _error = 'Failed to verify email';
      return false;
    } catch (e) {
      debugPrint('Email verification error: $e');
      _error = 'Failed to verify email';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshUserData() async {
    try {
      final userData = await _authService.getUser();
      if (userData != null && userData['email_verified_at'] != null) {
        _emailVerifiedAt = DateTime.parse(userData['email_verified_at']);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Refresh user data error: $e');
    }
  }

  Future<void> updateEmailVerificationStatus() async {
    try {
      final userData = await _authService.getUser();
      if (userData != null && userData['email_verified_at'] != null) {
        _emailVerifiedAt = DateTime.parse(userData['email_verified_at']);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Update email verification status error: $e');
    }
  }

  void clearError() {
    _clearErrors();
  }
}
