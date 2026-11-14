import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/user_model.dart';

/// Result wrapper for authentication operations providing success status and error feedback
class AuthResult {
  final bool isSuccess;
  final String? errorMessage;
  final String? message;

  const AuthResult._({required this.isSuccess, this.errorMessage, this.message});

  factory AuthResult.success([String? message]) =>
      AuthResult._(isSuccess: true, message: message);

  factory AuthResult.failure(String error) =>
      AuthResult._(isSuccess: false, errorMessage: error);
}

class AuthService extends ChangeNotifier {
  static const String _keyJwtToken = 'vibetune_jwt_token';
  static const String _keyIsLoggedIn = 'vibetune_is_logged_in';
  static const String _keyUserId = 'vibetune_user_id';
  static const String _keyUserName = 'vibetune_user_name';
  static const String _keyUserEmail = 'vibetune_user_email';
  static const String _keyUserRole = 'vibetune_user_role';
  static const String _keyUserLangs = 'vibetune_user_langs';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  UserModel? _currentUser;
  String? _token;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _lastError;

  AuthService() {
    _initLocalSession();
  }

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get token => _token;
  String? get lastError => _lastError;

  /// Initializes session by reading the secure JWT and validating against /api/auth/me
  Future<void> _initLocalSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
      final cachedId = prefs.getString(_keyUserId);

      // Handle persistent guest session
      if (isLoggedIn && (cachedId == 'usr_guest')) {
        final cachedName = prefs.getString(_keyUserName) ?? 'Guest Explorer';
        final cachedEmail = prefs.getString(_keyUserEmail) ?? 'guest@vibetune.com';
        final cachedLangs = prefs.getStringList(_keyUserLangs) ??
            const ['Hindi', 'Kannada', 'Telugu', 'Tamil', 'Malayalam'];

        _currentUser = UserModel(
          id: 'usr_guest',
          name: cachedName,
          email: cachedEmail,
          preferredLanguages: cachedLangs,
        );
        _token = 'guest_session';
        _isAuthenticated = true;
        notifyListeners();
        return;
      }

      final savedToken = await _secureStorage.read(key: _keyJwtToken);

      if (savedToken != null && savedToken.isNotEmpty && isLoggedIn) {
        _token = savedToken;
        // Verify token with backend GET /api/auth/me
        final verified = await _fetchUserProfile(savedToken);
        if (!verified) {
          // If server is offline or unreachable on boot, keep local session using cached credentials
          final cId = prefs.getString(_keyUserId) ?? 'usr_local';
          final cachedName = prefs.getString(_keyUserName) ?? 'Swathi';
          final cachedEmail = prefs.getString(_keyUserEmail) ?? 'swathi@vibetune.com';
          final cachedRole = prefs.getString(_keyUserRole) ?? 'user';
          final cachedLangs = prefs.getStringList(_keyUserLangs) ??
              const ['Hindi', 'Kannada', 'Telugu', 'Tamil', 'Malayalam'];

          _currentUser = UserModel(
            id: cId,
            name: cachedName,
            email: cachedEmail,
            role: cachedRole,
            preferredLanguages: cachedLangs,
          );
          _isAuthenticated = true;
          notifyListeners();
        }
      }
    } catch (_) {
      // Graceful error handling
    }
  }

  /// Validates JWT and retrieves latest user profile from GET /api/auth/me
  Future<bool> refreshUserProfile() async {
    if (_token == null || _token == 'guest_session' || _currentUser?.id == 'usr_guest') {
      return true;
    }
    return await _fetchUserProfile(_token!);
  }

  /// Verifies a specific JWT token with GET /api/auth/me
  Future<bool> verifyToken(String jwtToken) async {
    return await _fetchUserProfile(jwtToken);
  }

  /// Internal implementation to validate JWT and update user profile from GET /api/auth/me
  Future<bool> _fetchUserProfile(String jwtToken) async {
    try {
      final uri = Uri.parse(ApiConfig.meUrl);
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true && data['user'] != null) {
          final userJson = data['user'] as Map<String, dynamic>;
          final prefs = await SharedPreferences.getInstance();
          final cachedLangs = prefs.getStringList(_keyUserLangs) ??
              const ['Hindi', 'Kannada', 'Telugu', 'Tamil', 'Malayalam'];

          _currentUser = UserModel.fromJson(userJson).copyWith(
            preferredLanguages: cachedLangs,
          );
          _isAuthenticated = true;
          notifyListeners();
          return true;
        }
      } else if (response.statusCode == 401) {
        // Token expired or invalid: clear session
        await _clearSession();
        notifyListeners();
        return false;
      }
    } catch (_) {
      // Server offline / network unreachable
    }
    return false;
  }

  /// Sign In with Email & Password via POST /api/auth/login
  Future<AuthResult> signIn(String email, String password) async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      final uri = Uri.parse(ApiConfig.loginUrl);
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim().toLowerCase(),
          'password': password.trim(),
        }),
      ).timeout(const Duration(seconds: 15));

      Map<String, dynamic> data = {};
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          data = decoded;
        }
      } catch (_) {
        final error = 'Server returned HTTP ${response.statusCode}. Expected JSON response.';
        _lastError = error;
        _isLoading = false;
        notifyListeners();
        return AuthResult.failure(error);
      }

      if (response.statusCode == 200 && data['success'] == true) {
        final token = data['token'] as String;
        final userJson = data['user'] as Map<String, dynamic>;

        _token = token;
        final prefs = await SharedPreferences.getInstance();
        final existingLangs = prefs.getStringList(_keyUserLangs) ??
            const ['Hindi', 'Kannada', 'Telugu', 'Tamil', 'Malayalam'];

        _currentUser = UserModel.fromJson(userJson).copyWith(
          preferredLanguages: existingLangs,
        );
        _isAuthenticated = true;

        // Persist token securely and save session metadata
        await _secureStorage.write(key: _keyJwtToken, value: token);
        await prefs.setBool(_keyIsLoggedIn, true);
        await prefs.setString(_keyUserId, _currentUser!.id);
        await prefs.setString(_keyUserName, _currentUser!.name);
        await prefs.setString(_keyUserEmail, _currentUser!.email);
        await prefs.setString(_keyUserRole, _currentUser!.role);
        await prefs.setStringList(_keyUserLangs, _currentUser!.preferredLanguages);

        _isLoading = false;
        notifyListeners();
        return AuthResult.success(data['message'] as String? ?? 'Login successful.');
      } else {
        final message = (data['message'] as String?) ?? 'Invalid email or password.';
        _lastError = message;
        _isLoading = false;
        notifyListeners();
        return AuthResult.failure(message);
      }
    } on SocketException catch (e) {
      final detail = e.osError?.message ?? e.message;
      final error = 'Unable to reach VibeTune server at ${ApiConfig.baseUrl}. Please verify the Node.js backend is running (port ${ApiConfig.port}). ($detail)';
      _lastError = error;
      _isLoading = false;
      notifyListeners();
      return AuthResult.failure(error);
    } on http.ClientException catch (e) {
      final error = 'Unable to reach VibeTune server (${ApiConfig.baseUrl}). ${e.message}';
      _lastError = error;
      _isLoading = false;
      notifyListeners();
      return AuthResult.failure(error);
    } on TimeoutException {
      final error = 'Connection timed out while contacting VibeTune server (${ApiConfig.baseUrl}). Please verify that the backend is running.';
      _lastError = error;
      _isLoading = false;
      notifyListeners();
      return AuthResult.failure(error);
    } catch (e) {
      final error = 'Sign in failed: ${e.toString()}';
      _lastError = error;
      _isLoading = false;
      notifyListeners();
      return AuthResult.failure(error);
    }
  }

  /// Sign Up a new user via POST /api/auth/signup
  Future<AuthResult> signUp({
    required String name,
    required String email,
    required String password,
    required List<String> preferredLanguages,
  }) async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    final trimmedEmail = email.trim().toLowerCase();
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (trimmedEmail.isEmpty || !emailRegex.hasMatch(trimmedEmail)) {
      final error = 'Please enter a valid email address.';
      _lastError = error;
      _isLoading = false;
      notifyListeners();
      return AuthResult.failure(error);
    }

    if (password.trim().length < 6) {
      final error = 'Password must be at least 6 characters.';
      _lastError = error;
      _isLoading = false;
      notifyListeners();
      return AuthResult.failure(error);
    }

    try {
      final uri = Uri.parse(ApiConfig.signupUrl);
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name.trim(),
          'email': trimmedEmail,
          'password': password.trim(),
        }),
      ).timeout(const Duration(seconds: 15));

      Map<String, dynamic> data = {};
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          data = decoded;
        }
      } catch (_) {
        final error = 'Server returned HTTP ${response.statusCode}. Expected JSON response.';
        _lastError = error;
        _isLoading = false;
        notifyListeners();
        return AuthResult.failure(error);
      }

      if (response.statusCode == 201 && data['success'] == true) {
        final token = data['token'] as String;
        final userJson = data['user'] as Map<String, dynamic>;

        _token = token;
        final langs = preferredLanguages.isNotEmpty
            ? preferredLanguages
            : const ['Hindi', 'Kannada', 'Telugu', 'Tamil', 'Malayalam'];

        _currentUser = UserModel.fromJson(userJson).copyWith(
          preferredLanguages: langs,
        );
        _isAuthenticated = true;

        // Persist token securely and save session metadata
        await _secureStorage.write(key: _keyJwtToken, value: token);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_keyIsLoggedIn, true);
        await prefs.setString(_keyUserId, _currentUser!.id);
        await prefs.setString(_keyUserName, _currentUser!.name);
        await prefs.setString(_keyUserEmail, _currentUser!.email);
        await prefs.setString(_keyUserRole, _currentUser!.role);
        await prefs.setStringList(_keyUserLangs, _currentUser!.preferredLanguages);

        _isLoading = false;
        notifyListeners();
        return AuthResult.success(data['message'] as String? ?? 'Registration successful.');
      } else {
        final message = (data['message'] as String?) ?? 'Registration failed. Please check your details.';
        _lastError = message;
        _isLoading = false;
        notifyListeners();
        return AuthResult.failure(message);
      }
    } on SocketException catch (e) {
      final detail = e.osError?.message ?? e.message;
      final error = 'Unable to reach VibeTune server at ${ApiConfig.baseUrl}. Please verify the Node.js backend is running (port ${ApiConfig.port}). ($detail)';
      _lastError = error;
      _isLoading = false;
      notifyListeners();
      return AuthResult.failure(error);
    } on http.ClientException catch (e) {
      final error = 'Unable to reach VibeTune server (${ApiConfig.baseUrl}). ${e.message}';
      _lastError = error;
      _isLoading = false;
      notifyListeners();
      return AuthResult.failure(error);
    } on TimeoutException {
      final error = 'Connection timed out while contacting VibeTune server (${ApiConfig.baseUrl}). Please verify that the backend is running.';
      _lastError = error;
      _isLoading = false;
      notifyListeners();
      return AuthResult.failure(error);
    } catch (e) {
      final error = 'Sign up failed: ${e.toString()}';
      _lastError = error;
      _isLoading = false;
      notifyListeners();
      return AuthResult.failure(error);
    }
  }

  /// Check backend connectivity and database health via GET /api/health
  Future<bool> checkBackendHealth() async {
    try {
      final uri = Uri.parse(ApiConfig.healthUrl);
      final response = await http.get(uri).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return decoded is Map<String, dynamic> && decoded['success'] == true;
      }
    } catch (_) {}
    return false;
  }

  /// Continue without account (Guest mode)
  void continueAsGuest() {
    _currentUser = const UserModel(
      id: 'usr_guest',
      name: 'Guest Explorer',
      email: 'guest@vibetune.com',
      preferredLanguages: ['Hindi', 'Kannada', 'Telugu', 'Tamil', 'Malayalam'],
    );
    _isAuthenticated = true;
    _token = 'guest_session';
    _saveGuestSessionLocally();
    notifyListeners();
  }

  Future<void> _saveGuestSessionLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsLoggedIn, true);
      await prefs.setString(_keyUserId, 'usr_guest');
      await prefs.setString(_keyUserName, 'Guest Explorer');
      await prefs.setString(_keyUserEmail, 'guest@vibetune.com');
      await prefs.setStringList(_keyUserLangs, const [
        'Hindi',
        'Kannada',
        'Telugu',
        'Tamil',
        'Malayalam',
      ]);
    } catch (_) {}
  }

  /// Sign out current user and clear token securely
  Future<void> signOut() async {
    await _clearSession();
    notifyListeners();
  }

  Future<void> _clearSession() async {
    _currentUser = null;
    _token = null;
    _isAuthenticated = false;
    try {
      await _secureStorage.delete(key: _keyJwtToken);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsLoggedIn, false);
      await prefs.remove(_keyUserId);
      await prefs.remove(_keyUserName);
      await prefs.remove(_keyUserEmail);
      await prefs.remove(_keyUserRole);
    } catch (_) {}
  }

  /// Update preferred music languages
  Future<void> updateLanguages(List<String> langs) async {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(preferredLanguages: langs);
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList(_keyUserLangs, langs);
      } catch (_) {}
      notifyListeners();
    }
  }
}
