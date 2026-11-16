import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song_model.dart';
import '../data/song_catalog.dart';
import 'audio_player_service.dart';

class PlaylistService extends ChangeNotifier {
  final List<Song> _allSongs = List.from(SongCatalog.allSongs);
  List<Song> _currentQueue = [];
  int _currentIndex = 0;
  final Set<String> _favoriteSongIds = {'hi_01', 'ka_01', 'te_01', 'ta_01'};
  final List<Song> _recentlyPlayed = [];
  String _selectedLanguage = 'All';
  String _searchQuery = '';

  PlaylistService() {
    _currentQueue = List.from(_allSongs);
    _loadFavorites();
  }

  List<Song> get allSongs => _allSongs;
  List<Song> get currentQueue => _currentQueue;
  int get currentIndex => _currentIndex;
  String get selectedLanguage => _selectedLanguage;
  String get searchQuery => _searchQuery;

  List<Song> get filteredSongs {
    return _allSongs.where((song) {
      final matchesLang = _selectedLanguage == 'All' ||
          song.language.toLowerCase() == _selectedLanguage.toLowerCase();
      final matchesSearch = _searchQuery.isEmpty ||
          song.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          song.artist.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          song.movieOrAlbum.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          song.genre.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesLang && matchesSearch;
    }).toList();
  }

  List<Song> get favoriteSongs {
    return _allSongs.where((song) => _favoriteSongIds.contains(song.id)).toList();
  }

  List<Song> get karaokeSongs {
    return _allSongs.where((song) => song.isKaraokeAvailable).toList();
  }

  List<Song> get recentlyPlayed => _recentlyPlayed;

  bool isFavorite(String songId) => _favoriteSongIds.contains(songId);

  void toggleFavorite(String songId) {
    if (_favoriteSongIds.contains(songId)) {
      _favoriteSongIds.remove(songId);
    } else {
      _favoriteSongIds.add(songId);
    }
    _saveFavorites();
    notifyListeners();
  }

  void setLanguage(String language) {
    _selectedLanguage = language;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query.trim();
    notifyListeners();
  }

  void playSong(Song song, AudioPlayerService playerService, {PlaybackMode mode = PlaybackMode.normal}) {
    final index = _currentQueue.indexWhere((s) => s.id == song.id);
    if (index != -1) {
      _currentIndex = index;
    } else {
      _currentQueue.insert(0, song);
      _currentIndex = 0;
    }

    _addToRecentlyPlayed(song);

    if (playerService.currentSong?.id == song.id && playerService.currentLyrics.isNotEmpty) {
      if (playerService.playbackMode != mode) {
        playerService.setPlaybackMode(mode);
      } else if (!playerService.isPlaying) {
        playerService.togglePlayPause();
      }
    } else {
      playerService.playSong(song, mode: mode);
    }
    notifyListeners();
  }

  void playSongAt(int index, AudioPlayerService playerService, {PlaybackMode mode = PlaybackMode.normal}) {
    if (index >= 0 && index < _currentQueue.length) {
      _currentIndex = index;
      final song = _currentQueue[index];
      _addToRecentlyPlayed(song);
      playerService.playSong(song, mode: mode);
      notifyListeners();
    }
  }

  void nextSong(AudioPlayerService playerService) {
    if (_currentQueue.isEmpty) return;

    final hasPlayable = _currentQueue.any((s) => s.isPlayable);
    if (!hasPlayable) return;

    int nextIndex = _currentIndex;
    for (int attempts = 0; attempts < _currentQueue.length; attempts++) {
      if (playerService.isShuffle) {
        final rng = Random();
        nextIndex = rng.nextInt(_currentQueue.length);
      } else {
        nextIndex = (nextIndex + 1) % _currentQueue.length;
      }
      if (_currentQueue[nextIndex].isPlayable) {
        _currentIndex = nextIndex;
        break;
      }
    }

    final song = _currentQueue[_currentIndex];
    if (song.isPlayable) {
      _addToRecentlyPlayed(song);
      playerService.playSong(song, mode: playerService.playbackMode);
      notifyListeners();
    }
  }

  void previousSong(AudioPlayerService playerService) {
    if (_currentQueue.isEmpty) return;

    final hasPlayable = _currentQueue.any((s) => s.isPlayable);
    if (!hasPlayable) return;

    int prevIndex = _currentIndex;
    for (int attempts = 0; attempts < _currentQueue.length; attempts++) {
      if (playerService.isShuffle) {
        final rng = Random();
        prevIndex = rng.nextInt(_currentQueue.length);
      } else {
        prevIndex = (prevIndex - 1 + _currentQueue.length) % _currentQueue.length;
      }
      if (_currentQueue[prevIndex].isPlayable) {
        _currentIndex = prevIndex;
        break;
      }
    }

    final song = _currentQueue[_currentIndex];
    if (song.isPlayable) {
      _addToRecentlyPlayed(song);
      playerService.playSong(song, mode: playerService.playbackMode);
      notifyListeners();
    }
  }

  void _addToRecentlyPlayed(Song song) {
    _recentlyPlayed.removeWhere((s) => s.id == song.id);
    _recentlyPlayed.insert(0, song);
    if (_recentlyPlayed.length > 20) {
      _recentlyPlayed.removeLast();
    }
  }

  Future<void> _loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList('vibetune_favorites');
      if (saved != null && saved.isNotEmpty) {
        _favoriteSongIds.clear();
        _favoriteSongIds.addAll(saved);
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('vibetune_favorites', _favoriteSongIds.toList());
    } catch (_) {}
  }
}
