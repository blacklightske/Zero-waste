import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_service.dart';

class DjangoAuthService extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  static const _storage = FlutterSecureStorage();
  
  Map<String, dynamic>? _currentUser;
  Map<String, dynamic>? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  
  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  DjangoAuthService() {
    _loadUserFromStorage();
  }

  // Load user data from secure storage on app start
  Future<void> _loadUserFromStorage() async {
    try {
      final token = await _storage.read(key: 'auth_token');
      final userId = await _storage.read(key: 'user_id');
      final userName = await _storage.read(key: 'user_name');
      final userEmail = await _storage.read(key: 'user_email');
      
      if (token != null && userId != null) {
        _currentUser = {
          'id': userId,
          'name': userName,
          'email': userEmail,
        };
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading user from storage: $e');
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set error message
  void _setError(String error) {
    _errorMessage = error;
    _setLoading(false);
  }

  // Sign up with email and password
  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      _setLoading(true);
      clearError();

      final result = await _apiService.signUp(
        email: email,
        password: password,
        name: name,
      );

      if (result != null) {
        _currentUser = result['user'];
        // Store user data in secure storage
        await _storage.write(key: 'user_name', value: _currentUser!['name']);
        await _storage.write(key: 'user_email', value: _currentUser!['email']);
        // Reload token and user info from storage to ensure consistency
        await _loadUserFromStorage();
        _setLoading(false);
        notifyListeners();
        return true;
      }
      _setError('Failed to create account');
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // Sign in with email and password
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      clearError();

      final result = await _apiService.signIn(
        email: email.trim().toLowerCase(),
        password: password.trim(),
      );

      if (result != null && result.containsKey('user')) {
        _currentUser = result['user'];
        // Store user data in secure storage
        await _storage.write(key: 'user_name', value: _currentUser!['name']);
        await _storage.write(key: 'user_email', value: _currentUser!['email']);
        // Reload token and user info from storage to ensure consistency
        await _loadUserFromStorage();
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _setError('Failed to sign in. Please check your credentials.');
        return false;
      }
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _apiService.signOut();
    } catch (e) {
      debugPrint('Sign out error: $e');
    } finally {
      _currentUser = null;
      await _storage.delete(key: 'auth_token');
      await _storage.delete(key: 'user_id');
      await _storage.delete(key: 'user_name');
      await _storage.delete(key: 'user_email');
      notifyListeners();
    }
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    try {
      _setLoading(true);
      clearError();

      final success = await _apiService.resetPassword(email);
      
      _setLoading(false);
      return success;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // Get current user's display name
  String get userName {
    return _currentUser?['name'] ?? _currentUser?['email']?.split('@')[0] ?? 'User';
  }

  // Get current user's email
  String get userEmail {
    return _currentUser?['email'] ?? '';
  }

  // Get current user's ID
  String? get userId {
    return _currentUser?['id']?.toString();
  }

  // Check if user is authenticated (for compatibility)
  bool get user => isAuthenticated;
}