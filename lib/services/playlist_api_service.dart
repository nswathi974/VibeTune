import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/playlist_model.dart';

class PlaylistApiService extends ChangeNotifier {
  static const String _cacheKey = 'vibetune_cached_playlists';

  List<PlaylistModel> _playlists = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<PlaylistModel> get playlists => _playlists;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  PlaylistApiService() {
    _loadFromCache();
  }

  Map<String, String> _headers(String? token) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (token != null && token.isNotEmpty && token != 'guest_session') {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// Load playlists cached in local storage
  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_cacheKey);
      if (cachedJson != null && cachedJson.isNotEmpty) {
        final decoded = jsonDecode(cachedJson) as List<dynamic>;
        _playlists = decoded
            .map((item) => PlaylistModel.fromJson(item as Map<String, dynamic>))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[PlaylistApiService] Error loading cache: $e');
    }
  }

  /// Save playlists to local storage cache
  Future<void> _saveToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_playlists.map((p) => p.toJson()).toList());
      await prefs.setString(_cacheKey, encoded);
    } catch (e) {
      debugPrint('[PlaylistApiService] Error saving cache: $e');
    }
  }

  /// Fetch all playlists owned by the authenticated user from MongoDB
  Future<void> fetchPlaylists({String? token}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // If guest mode or no token, keep cached local playlists
    if (token == null || token.isEmpty || token == 'guest_session') {
      await _loadFromCache();
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final response = await http
          .get(
            Uri.parse(ApiConfig.playlistsUrl),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['playlists'] is List) {
          final list = (data['playlists'] as List)
              .map((item) => PlaylistModel.fromJson(item as Map<String, dynamic>))
              .toList();
          _playlists = list;
          await _saveToCache();
        }
      } else {
        final error = jsonDecode(response.body);
        _errorMessage = error['message']?.toString() ?? 'Failed to load playlists.';
      }
    } catch (e) {
      debugPrint('[PlaylistApiService] Fetch error: $e');
      _errorMessage = 'Network error loading playlists. Showing local cache.';
      await _loadFromCache();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create a new playlist
  Future<PlaylistModel?> createPlaylist(
    String name, {
    String description = '',
    String? token,
    List<String>? initialSongs,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (token != null && token.isNotEmpty && token != 'guest_session') {
        final response = await http
            .post(
              Uri.parse(ApiConfig.playlistsUrl),
              headers: _headers(token),
              body: jsonEncode({
                'name': name.trim(),
                'description': description.trim(),
                'songs': initialSongs ?? [],
              }),
            )
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 201) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final created = PlaylistModel.fromJson(data['playlist'] as Map<String, dynamic>);
          _playlists.insert(0, created);
          await _saveToCache();
          _isLoading = false;
          notifyListeners();
          return created;
        } else {
          final error = jsonDecode(response.body);
          _errorMessage = error['message']?.toString() ?? 'Failed to create playlist.';
        }
      } else {
        // Guest mode / offline creation
        final localId = 'local_${DateTime.now().millisecondsSinceEpoch}';
        final localPlaylist = PlaylistModel(
          id: localId,
          name: name.trim(),
          description: description.trim(),
          songIds: initialSongs ?? [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        _playlists.insert(0, localPlaylist);
        await _saveToCache();
        _isLoading = false;
        notifyListeners();
        return localPlaylist;
      }
    } catch (e) {
      debugPrint('[PlaylistApiService] Create error: $e');
      _errorMessage = 'Could not reach server to create playlist.';
    }

    _isLoading = false;
    notifyListeners();
    return null;
  }

  /// Rename or update playlist description
  Future<bool> renamePlaylist(
    String playlistId,
    String newName, {
    String? newDescription,
    String? token,
  }) async {
    try {
      if (token != null && token.isNotEmpty && token != 'guest_session' && !playlistId.startsWith('local_')) {
        final response = await http
            .put(
              Uri.parse('${ApiConfig.playlistsUrl}/$playlistId'),
              headers: _headers(token),
              body: jsonEncode({
                'name': newName.trim(),
                if (newDescription != null) 'description': newDescription.trim(),
              }),
            )
            .timeout(const Duration(seconds: 10));

        if (response.statusCode != 200) {
          final error = jsonDecode(response.body);
          _errorMessage = error['message']?.toString() ?? 'Failed to update playlist.';
          notifyListeners();
          return false;
        }
      }

      final index = _playlists.indexWhere((p) => p.id == playlistId);
      if (index != -1) {
        _playlists[index] = _playlists[index].copyWith(
          name: newName.trim(),
          description: newDescription?.trim() ?? _playlists[index].description,
          updatedAt: DateTime.now(),
        );
        await _saveToCache();
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('[PlaylistApiService] Update error: $e');
      _errorMessage = 'Failed to update playlist: $e';
      notifyListeners();
    }
    return false;
  }

  /// Delete a playlist
  Future<bool> deletePlaylist(String playlistId, {String? token}) async {
    try {
      if (token != null && token.isNotEmpty && token != 'guest_session' && !playlistId.startsWith('local_')) {
        final response = await http
            .delete(
              Uri.parse('${ApiConfig.playlistsUrl}/$playlistId'),
              headers: _headers(token),
            )
            .timeout(const Duration(seconds: 10));

        if (response.statusCode != 200) {
          final error = jsonDecode(response.body);
          _errorMessage = error['message']?.toString() ?? 'Failed to delete playlist.';
          notifyListeners();
          return false;
        }
      }

      _playlists.removeWhere((p) => p.id == playlistId);
      await _saveToCache();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[PlaylistApiService] Delete error: $e');
      _errorMessage = 'Failed to delete playlist: $e';
      notifyListeners();
    }
    return false;
  }

  /// Add a song to playlist
  Future<bool> addSongToPlaylist(String playlistId, String songId, {String? token}) async {
    try {
      if (token != null && token.isNotEmpty && token != 'guest_session' && !playlistId.startsWith('local_')) {
        final response = await http
            .post(
              Uri.parse('${ApiConfig.playlistsUrl}/$playlistId/songs'),
              headers: _headers(token),
              body: jsonEncode({'songId': songId}),
            )
            .timeout(const Duration(seconds: 10));

        if (response.statusCode != 200) {
          final error = jsonDecode(response.body);
          _errorMessage = error['message']?.toString() ?? 'Failed to add song.';
          notifyListeners();
          return false;
        }
      }

      final index = _playlists.indexWhere((p) => p.id == playlistId);
      if (index != -1) {
        if (!_playlists[index].songIds.contains(songId)) {
          final updatedSongs = List<String>.from(_playlists[index].songIds)..add(songId);
          _playlists[index] = _playlists[index].copyWith(
            songIds: updatedSongs,
            updatedAt: DateTime.now(),
          );
          await _saveToCache();
          notifyListeners();
          return true;
        }
      }
    } catch (e) {
      debugPrint('[PlaylistApiService] Add song error: $e');
      _errorMessage = 'Failed to add song: $e';
      notifyListeners();
    }
    return false;
  }

  /// Remove a song from playlist
  Future<bool> removeSongFromPlaylist(String playlistId, String songId, {String? token}) async {
    try {
      if (token != null && token.isNotEmpty && token != 'guest_session' && !playlistId.startsWith('local_')) {
        final response = await http
            .delete(
              Uri.parse('${ApiConfig.playlistsUrl}/$playlistId/songs/$songId'),
              headers: _headers(token),
            )
            .timeout(const Duration(seconds: 10));

        if (response.statusCode != 200) {
          final error = jsonDecode(response.body);
          _errorMessage = error['message']?.toString() ?? 'Failed to remove song.';
          notifyListeners();
          return false;
        }
      }

      final index = _playlists.indexWhere((p) => p.id == playlistId);
      if (index != -1) {
        final updatedSongs = List<String>.from(_playlists[index].songIds)..remove(songId);
        _playlists[index] = _playlists[index].copyWith(
          songIds: updatedSongs,
          updatedAt: DateTime.now(),
        );
        await _saveToCache();
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('[PlaylistApiService] Remove song error: $e');
      _errorMessage = 'Failed to remove song: $e';
      notifyListeners();
    }
    return false;
  }
}

