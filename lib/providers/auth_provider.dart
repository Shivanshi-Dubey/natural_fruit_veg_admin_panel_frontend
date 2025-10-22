import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  bool _isLoggedIn = false;
  bool _isLoading = false;
  String? _token;
  String? _errorMessage;

  // Getters
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String? get token => _token;
  String? get errorMessage => _errorMessage;

  // Initialize authentication state on app start
  Future<void> initializeAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await AuthService.getToken();
      
      if (token != null && token.isNotEmpty) {
        _token = token;
        _isLoggedIn = true;
      } else {
        _isLoggedIn = false;
        _token = null;
      }
    } catch (e) {
      debugPrint('Auth initialization error: $e');
      _isLoggedIn = false;
      _token = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Login method
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await AuthService.login(email, password);
      
      if (success) {
        _isLoggedIn = true;
        _token = await AuthService.getToken();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Login failed. Please check your credentials.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'An error occurred during login: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Logout method
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await AuthService.logout();
      
      _isLoggedIn = false;
      _token = null;
      _errorMessage = null;
    } catch (e) {
      debugPrint('Logout error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Check if token is valid
  Future<bool> isTokenValid() async {
    if (_token == null) return false;
    
    try {
      final token = await AuthService.getToken();
      return token != null && token.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
