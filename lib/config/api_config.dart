import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

/// Centralized API configuration for VibeTune backend communication.
class ApiConfig {
  static const int port = 5000;
  static String? _customBaseUrl;

  /// Allows setting a custom IP (e.g., LAN IP for physical device testing)
  static void setCustomBaseUrl(String? url) {
    _customBaseUrl = url;
  }

  /// Returns the base URL based on the runtime environment:
  /// - Custom override (if set)
  /// - Android Emulator: http://10.0.2.2:5000
  /// - Web / Windows / macOS / Linux / iOS: http://127.0.0.1:5000
  static String get baseUrl {
    if (_customBaseUrl != null && _customBaseUrl!.isNotEmpty) {
      return _customBaseUrl!;
    }
    if (kIsWeb) {
      return 'http://127.0.0.1:$port';
    }
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:$port';
      }
    } catch (_) {
      // Fallback if Platform check is unsupported
    }
    return 'http://127.0.0.1:$port';
  }

  static String get signupUrl => '$baseUrl/api/auth/signup';
  static String get loginUrl => '$baseUrl/api/auth/login';
  static String get meUrl => '$baseUrl/api/auth/me';
  static String get healthUrl => '$baseUrl/api/health';
  static String get playlistsUrl => '$baseUrl/api/playlists';
}
