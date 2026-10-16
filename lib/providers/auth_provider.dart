import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService;
  AppUser? _user;
  String? _token;
  bool _isLoading = false;
  String? _errorMessage;

  AuthProvider(this._apiService);

  AppUser? get user => _user;
  String? get token => _token;
  bool get isAuthenticated => _token != null && _user != null;
  bool get isAdmin => _user?.isAdmin ?? false;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // for testing different user roles in widget tests
  @visibleForTesting
  void setUserForTesting(AppUser? user, [String? token = 'mock_token']) {
    _user = user;
    _token = token;
    notifyListeners();
  }

  static const String _keyToken = 'auth_token';
  static const String _keyUser = 'auth_user';

  // Attempt auto-login on startup
  Future<void> tryAutoLogin() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString(_keyToken);
      final savedUserJson = prefs.getString(_keyUser);

      if (savedToken != null && savedUserJson != null) {
        _token = savedToken;
        _user = AppUser.fromJson(jsonDecode(savedUserJson));
        _apiService.setToken(savedToken);

        // Verify with server in background
        try {
          final refreshed = await _apiService.getMe();
          _user = refreshed;
          await prefs.setString(_keyUser, jsonEncode(_user!.toJson()));
        } catch (_) {
          // Keep offline cached user or let it fail gracefully
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('[Auth] Auto login error: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Login
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _apiService.login(email, password);
      _token = result['token'];
      _user = result['user'];
      _apiService.setToken(_token);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyToken, _token!);
      await prefs.setString(_keyUser, jsonEncode(_user!.toJson()));

      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred during login.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Signup
  Future<bool> signup(String name, String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _apiService.signup(name, email, password);
      _token = result['token'];
      _user = result['user'];
      _apiService.setToken(_token);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyToken, _token!);
      await prefs.setString(_keyUser, jsonEncode(_user!.toJson()));

      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred during signup.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Forgot password - returns code if available for easy testing
  Future<Map<String, dynamic>?> forgotPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _apiService.forgotPassword(email);
      _isLoading = false;
      notifyListeners();
      return result;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _errorMessage = 'Could not request password reset. Please try again.';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Reset password
  Future<bool> resetPassword(String email, String code, String newPassword) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.resetPassword(email, code, newPassword);
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Could not reset password. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    _token = null;
    _user = null;
    _apiService.setToken(null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUser);
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
