import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart' show LoopMode, AudioPlayer;
import 'package:youtube_player_flutter/youtube_player_flutter.dart' as yt;
import '../models/song_model.dart';
import '../models/lyric_line_model.dart';
import '../data/song_catalog.dart';
import 'lyrics_service.dart';
import 'lrclib_service.dart';
import 'translation_service.dart';
import '../config/api_config.dart';
import 'playback/playback_adapter.dart';
import 'playback/just_audio_adapter.dart';
import 'playback/youtube_adapter.dart';

/// AudioPlayerService
///
/// Refactored to a unified Adapter-Based Architecture (Phase 2):
/// - JustAudioAdapter: High-fidelity multi-track playback for local assets & Archive.org streams.
/// - YouTubeAdapter: Policy-compliant embedded playback using YouTube's official IFrame Player.
///
/// Provides a single, uniform state and control API for all screens, preventing race conditions,
/// memory leaks, and duplicate controllers while preserving genuine Karaoke stem switching,
/// honest Sing-Along behavior, and real-time lyrics synchronization.
class AudioPlayerService extends ChangeNotifier {
  // Underlying playback adapters
  final JustAudioAdapter _justAudioAdapter;
  YouTubeAdapter? _youtubeAdapter;
  PlaybackAdapter? _activeAdapter;

  // Active subscriptions to the current adapter
  StreamSubscription<Duration>? _activePositionSub;
  StreamSubscription<Duration>? _activeDurationSub;
  StreamSubscription<PlaybackEngineState>? _activeStateSub;
  StreamSubscription<String?>? _activeErrorSub;
  StreamSubscription<void>? _activeCompletedSub;

  // Concurrency & race condition guard
  int _operationEpoch = 0;

  Song? _currentSong;
  PlaybackMode _playbackMode = PlaybackMode.normal;
  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  String? _playbackErrorMessage;

  // Synchronized & Multilingual Lyrics State
  List<LyricLine> _currentLyrics = [];
  List<LyricLine> _originalLyrics = [];
  String? _plainLyrics;
  int _activeLyricIndex = 0;
  String _currentLyricLanguage = 'Original';
  bool _isTranslating = false;
  String _lyricSourceDescription = 'Original Lyrics';
  bool _isSyncedLyrics = true;

  bool _isShuffle = false;
  LoopMode _loopMode = LoopMode.off;
  double _volume = 1.0;
  double _speed = 1.0;

  // Navigation callbacks
  VoidCallback? onNextRequested;
  VoidCallback? onPreviousRequested;

  AudioPlayerService({JustAudioAdapter? justAudioAdapter})
      : _justAudioAdapter = justAudioAdapter ?? JustAudioAdapter() {
    _activeAdapter = _justAudioAdapter;
    _bindAdapterStreams(_justAudioAdapter);
  }

  // Backwards-compatible and Unified Getters
  AudioPlayer get rawPlayer => _justAudioAdapter.primaryPlayer;
  yt.YoutubePlayerController? get youtubeController => _youtubeAdapter?.youtubeController;
  PlaybackAdapter? get activeAdapter => _activeAdapter;
  bool get isCurrentSongYouTube => _currentSong?.isYouTubeTrack == true;
  Song? get currentSong => _currentSong;
  PlaybackMode get playbackMode => _playbackMode;
  bool get isNormalMode => _playbackMode == PlaybackMode.normal;
  bool get isKaraokeMode => _playbackMode == PlaybackMode.karaoke;
  bool get hasSecondaryTrack => _activeAdapter?.hasSecondaryTrack ?? false;
  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  Duration get position => _position;
  Duration get duration => _duration;
  String? get playbackErrorMessage => _playbackErrorMessage;
  List<LyricLine> get currentLyrics => _currentLyrics;
  String? get plainLyrics => _plainLyrics;
  int get activeLyricIndex => _activeLyricIndex;
  String get currentLyricLanguage => _currentLyricLanguage;
  bool get isTranslating => _isTranslating;
  String get lyricSourceDescription => _lyricSourceDescription;
  bool get isSyncedLyrics => _isSyncedLyrics;
  bool get isShuffle => _isShuffle;
  LoopMode get loopMode => _loopMode;
  double get volume => _volume;
  double get speed => _speed;

  void clearPlaybackError() {
    _playbackErrorMessage = null;
    notifyListeners();
  }

  void _bindAdapterStreams(PlaybackAdapter adapter) {
    _unbindAdapterStreams();

    _activePositionSub = adapter.positionStream.listen((pos) {
      _position = pos;
      if (_currentLyrics.isNotEmpty) {
        final newIndex = LyricsService.getActiveLineIndex(pos, _currentLyrics);
        if (newIndex != _activeLyricIndex) {
          _activeLyricIndex = newIndex;
        }
      }
      notifyListeners();
    });

    _activeDurationSub = adapter.durationStream.listen((dur) {
      if (dur > Duration.zero && dur != _duration) {
        _duration = dur;
        notifyListeners();
      }
    });

    _activeStateSub = adapter.stateStream.listen((state) {
      final wasPlaying = _isPlaying;
      final wasLoading = _isLoading;

      _isPlaying = state == PlaybackEngineState.playing;
      _isLoading = state == PlaybackEngineState.loading;

      if (state == PlaybackEngineState.playing) {
        _playbackErrorMessage = null;
      }

      if (wasPlaying != _isPlaying || wasLoading != _isLoading) {
        notifyListeners();
      }
    });

    _activeErrorSub = adapter.errorStream.listen((err) {
      _playbackErrorMessage = err;
      if (err != null) {
        _isLoading = false;
        _isPlaying = false;
      }
      notifyListeners();
    });

    _activeCompletedSub = adapter.onCompletedStream.listen((_) {
      if (_loopMode == LoopMode.one) {
        seek(Duration.zero);
        play();
      } else {
        onNextRequested?.call();
      }
    });
  }

  void _unbindAdapterStreams() {
    _activePositionSub?.cancel();
    _activePositionSub = null;
    _activeDurationSub?.cancel();
    _activeDurationSub = null;
    _activeStateSub?.cancel();
    _activeStateSub = null;
    _activeErrorSub?.cancel();
    _activeErrorSub = null;
    _activeCompletedSub?.cancel();
    _activeCompletedSub = null;
  }

  /// Plays a given song with unified adapter dispatching.
  /// Prevents race conditions, overlapping audio, and duplicate controllers.
  Future<void> playSong(
    Song song, {
    PlaybackMode mode = PlaybackMode.normal,
    Duration? startPosition,
    bool autoPlay = true,
  }) async {
    final currentEpoch = ++_operationEpoch;

    // Check if the exact same song is already active
    if (_currentSong?.id == song.id) {
      if (_playbackMode == mode) {
        if (!_isPlaying && autoPlay) {
          await togglePlayPause();
        }
        return;
      } else {
        // Toggle mode on the currently active track seamlessly
        await setPlaybackMode(mode);
        return;
      }
    }

    final isNewSong = _currentSong?.id != song.id;
    _currentSong = song;
    _playbackMode = mode;
    _playbackErrorMessage = null;
    _isLoading = true;
    _position = startPosition ?? Duration.zero;
    _duration = song.duration;
    notifyListeners();

    // Trigger lyrics load immediately
    if (isNewSong || _currentLyrics.isEmpty) {
      _currentLyrics = [];
      _originalLyrics = [];
      _activeLyricIndex = 0;
      unawaited(_loadLyricsForSong(song));
    }

    // Handle Unplayable Commercial Placeholders (Group D) honestly
    if (!song.isPlayable && !song.isYouTubeTrack && song.normalAudioPath.isEmpty) {
      _isLoading = false;
      _isPlaying = false;
      _playbackErrorMessage = song.audioSourceNotice ?? 'Streaming license required for this track.';
      notifyListeners();
      return;
    }

    // Switch between YouTube and JustAudio adapters cleanly
    if (song.isYouTubeTrack) {
      // 1. Stop local audio engine completely to prevent audio collisions
      await _justAudioAdapter.stop();

      // 2. Safely dispose any previous YouTube controller before creating a new one
      if (_youtubeAdapter != null) {
        await _youtubeAdapter!.dispose();
        _youtubeAdapter = null;
      }

      // 3. Instantiate fresh YouTubeAdapter
      final ytAdapter = YouTubeAdapter();
      _youtubeAdapter = ytAdapter;
      _activeAdapter = ytAdapter;
      _bindAdapterStreams(ytAdapter);

      // Apply current playback settings
      await ytAdapter.setVolume(_volume);
      await ytAdapter.setSpeed(_speed);
      await ytAdapter.setLoopMode(_loopMode);

      // 4. Load YouTube track
      await ytAdapter.load(
        song,
        initialPosition: startPosition,
        autoPlay: autoPlay,
        mode: mode,
      );
    } else {
      // Local Audio Asset or Archive.org Stream
      // 1. Properly dispose YouTube controller before starting local playback
      if (_youtubeAdapter != null) {
        await _youtubeAdapter!.dispose();
        _youtubeAdapter = null;
      }

      // 2. Set JustAudioAdapter as active
      _activeAdapter = _justAudioAdapter;
      _bindAdapterStreams(_justAudioAdapter);

      // Apply current playback settings
      await _justAudioAdapter.setVolume(_volume);
      await _justAudioAdapter.setSpeed(_speed);
      await _justAudioAdapter.setLoopMode(_loopMode);

      // 3. Load audio source
      await _justAudioAdapter.load(
        song,
        initialPosition: startPosition,
        autoPlay: autoPlay,
        mode: mode,
      );
    }

    // Check if a newer playSong call was initiated while loading
    if (_operationEpoch != currentEpoch) {
      return;
    }

    _isLoading = false;
    _isPlaying = autoPlay;
    notifyListeners();
  }

  /// Starts or resumes playback
  Future<void> play() async {
    if (_activeAdapter != null) {
      await _activeAdapter!.play();
      _isPlaying = true;
      notifyListeners();
    }
  }

  /// Pauses playback
  Future<void> pause() async {
    if (_activeAdapter != null) {
      await _activeAdapter!.pause();
      _isPlaying = false;
      notifyListeners();
    }
  }

  /// Toggles Play / Pause across all source types
  Future<void> togglePlayPause() async {
    if (_activeAdapter == null || _currentSong == null) {
      final firstPlayable = SongCatalog.allSongs.firstWhere(
        (s) => s.isPlayable && (s.normalAudioPath.isNotEmpty || s.isYouTubeTrack),
        orElse: () => SongCatalog.allSongs.first,
      );
      await playSong(firstPlayable);
      return;
    }

    if (_isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  /// Stops all audio/video playback and resets position
  Future<void> stop() async {
    if (_youtubeAdapter != null) {
      await _youtubeAdapter!.stop();
    }
    await _justAudioAdapter.stop();
    _isPlaying = false;
    _position = Duration.zero;
    notifyListeners();
  }

  /// Seeks to a specific timestamp across any active source
  Future<void> seek(Duration targetPosition) async {
    _position = targetPosition;
    if (_currentLyrics.isNotEmpty) {
      _activeLyricIndex = LyricsService.getActiveLineIndex(targetPosition, _currentLyrics);
    }
    notifyListeners();

    if (_activeAdapter != null) {
      await _activeAdapter!.seek(targetPosition);
    }
  }

  /// Sets audio volume (0.0 to 1.0)
  Future<void> setVolume(double val) async {
    _volume = val.clamp(0.0, 1.0);
    if (_activeAdapter != null) {
      await _activeAdapter!.setVolume(_volume);
    }
    notifyListeners();
  }

  /// Sets playback speed (0.5x to 2.0x)
  Future<void> setSpeed(double val) async {
    _speed = val.clamp(0.5, 2.0);
    if (_activeAdapter != null) {
      await _activeAdapter!.setSpeed(_speed);
    }
    notifyListeners();
  }

  /// Toggles shuffle mode
  void toggleShuffle() {
    _isShuffle = !_isShuffle;
    notifyListeners();
  }

  /// Cycles repeat mode: off -> all -> one
  void cycleLoopMode() {
    if (_loopMode == LoopMode.off) {
      _loopMode = LoopMode.all;
    } else if (_loopMode == LoopMode.all) {
      _loopMode = LoopMode.one;
    } else {
      _loopMode = LoopMode.off;
    }
    if (_activeAdapter != null) {
      _activeAdapter!.setLoopMode(_loopMode);
    }
    notifyListeners();
  }

  /// Toggles between Normal (vocal) Mode and Karaoke (instrumental) Mode.
  /// Preserves the current playback timestamp for seamless transition!
  Future<void> toggleMode() async {
    if (_currentSong == null) return;

    final targetMode = _playbackMode == PlaybackMode.normal
        ? PlaybackMode.karaoke
        : PlaybackMode.normal;

    await setPlaybackMode(targetMode);
  }

  /// Explicitly sets the mode to either Normal or Karaoke
  Future<void> setPlaybackMode(PlaybackMode newMode) async {
    if (_currentSong == null) return;

    _playbackMode = newMode;

    if (_activeAdapter != null) {
      await _activeAdapter!.setPlaybackMode(newMode);
    }

    if (newMode == PlaybackMode.karaoke && !hasSecondaryTrack) {
      if (isCurrentSongYouTube) {
        _playbackErrorMessage =
            'Karaoke instrumental stem unavailable for "${_currentSong!.title}". Sing-Along mode active with original audio.';
      } else {
        _playbackErrorMessage =
            'Karaoke instrumental stem is not available for "${_currentSong!.title}". Vocal sing-along active.';
      }
    } else {
      _playbackErrorMessage = null;
    }

    notifyListeners();
  }

  /// Loads an AI separated instrumental stem dynamically (e.g. from backend separation API)
  /// and enables Karaoke mode without interrupting or resetting playback position!
  Future<void> loadDynamicKaraokeStem(String stemUrl) async {
    if (_currentSong == null) return;

    final fullUrl = stemUrl.startsWith('http://') || stemUrl.startsWith('https://')
        ? stemUrl
        : '${ApiConfig.baseUrl}$stemUrl';

    try {
      await _justAudioAdapter.loadDynamicKaraokeStem(
        fullUrl,
        currentPosition: _position,
        speed: _speed,
        isPlaying: _isPlaying,
      );

      _activeAdapter = _justAudioAdapter;
      _bindAdapterStreams(_justAudioAdapter);
      _playbackMode = PlaybackMode.karaoke;
      _playbackErrorMessage = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading dynamic karaoke stem from "$fullUrl": $e');
      _playbackErrorMessage = 'Unable to load separated instrumental stem: $e';
      notifyListeners();
    }
  }

  /// Next track
  void next() {
    onNextRequested?.call();
  }

  /// Previous track
  void previous() {
    if (_position > const Duration(seconds: 3)) {
      seek(Duration.zero);
    } else {
      onPreviousRequested?.call();
    }
  }

  Future<void> _loadLyricsForSong(Song song) async {
    _isTranslating = false;
    _currentLyricLanguage = 'Original';
    _plainLyrics = null;

    // 1. Try local verified asset if defined
    if (song.lyricsPath != null && song.lyricsPath!.isNotEmpty) {
      final assetLyrics = await LyricsService.loadLyricsFromAsset(song.lyricsPath!);
      if (assetLyrics.isNotEmpty) {
        _currentLyrics = assetLyrics;
        _originalLyrics = List.from(assetLyrics);
        _plainLyrics = assetLyrics.map((l) => l.text).join('\n');
        _activeLyricIndex = 0;
        _lyricSourceDescription = 'VibeTune Studio Synced Lyrics (${song.language})';
        _isSyncedLyrics = true;
        notifyListeners();
        return;
      }
    }

    // 2. Fetch from LRCLIB Cloud API (exact -> search -> cache)
    final lrclibResult = await LrclibService.fetchLyrics(
      title: song.title,
      artist: song.artist,
      album: song.movieOrAlbum,
      durationSeconds: song.duration.inSeconds,
    );

    if (lrclibResult.isFound) {
      _plainLyrics = lrclibResult.plainLyrics;
      _lyricSourceDescription = lrclibResult.sourceDescription;
      _isSyncedLyrics = lrclibResult.isSynced;

      if (lrclibResult.isSynced && lrclibResult.lyrics.isNotEmpty) {
        _currentLyrics = lrclibResult.lyrics;
        _originalLyrics = List.from(lrclibResult.lyrics);
        _activeLyricIndex = 0;
      } else {
        // Plain unsynchronized lyrics or instrumental
        _currentLyrics = [];
        _originalLyrics = [];
        _activeLyricIndex = -1;
      }
      notifyListeners();
      return;
    }

    // 3. Honest missing lyrics handling: never display lyrics from another song
    _currentLyrics = [];
    _originalLyrics = [];
    _plainLyrics = null;
    _activeLyricIndex = -1;
    _isSyncedLyrics = false;
    _lyricSourceDescription = 'Lyrics not available for "${song.title}".';
    notifyListeners();
  }

  /// Changes the lyric language, performing line-by-line translation and preserving timestamps!
  Future<void> changeLyricLanguage(String targetLanguage) async {
    if (_currentSong == null || _originalLyrics.isEmpty) return;
    if (_currentLyricLanguage == targetLanguage) return;

    if (targetLanguage == 'Original') {
      _currentLyrics = List.from(_originalLyrics);
      _currentLyricLanguage = 'Original';
      _lyricSourceDescription = 'Original Lyrics (${_currentSong!.language})';
      notifyListeners();
      return;
    }

    _isTranslating = true;
    notifyListeners();

    try {
      final translated = await TranslationService.translateLyrics(
        lines: _originalLyrics,
        sourceLanguage: _currentSong!.language,
        targetLanguage: targetLanguage,
      );

      _currentLyrics = translated;
      _currentLyricLanguage = targetLanguage;
      _lyricSourceDescription = 'Translated to $targetLanguage (Machine Translation)';
    } catch (e) {
      debugPrint('Error translating lyrics to $targetLanguage: $e');
    } finally {
      _isTranslating = false;
      notifyListeners();
    }
  }

  /// Explicitly re-queries LRCLIB for the latest cloud lyrics
  Future<void> reloadLyricsFromLrclib() async {
    if (_currentSong == null) return;
    _isTranslating = true;
    notifyListeners();

    final lrclibResult = await LrclibService.fetchLyrics(
      title: _currentSong!.title,
      artist: _currentSong!.artist,
      album: _currentSong!.movieOrAlbum,
      durationSeconds: _currentSong!.duration.inSeconds,
    );

    if (lrclibResult.isFound) {
      _plainLyrics = lrclibResult.plainLyrics;
      _lyricSourceDescription = lrclibResult.sourceDescription;
      _isSyncedLyrics = lrclibResult.isSynced;
      _currentLyricLanguage = 'Original';

      if (lrclibResult.isSynced && lrclibResult.lyrics.isNotEmpty) {
        _currentLyrics = lrclibResult.lyrics;
        _originalLyrics = List.from(lrclibResult.lyrics);
        _activeLyricIndex = 0;
      } else {
        _currentLyrics = [];
        _originalLyrics = [];
        _activeLyricIndex = -1;
      }
    } else {
      _currentLyrics = [];
      _originalLyrics = [];
      _plainLyrics = null;
      _activeLyricIndex = -1;
      _isSyncedLyrics = false;
      _lyricSourceDescription = 'Lyrics not available for "${_currentSong!.title}".';
    }
    _isTranslating = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _unbindAdapterStreams();
    _youtubeAdapter?.dispose();
    _justAudioAdapter.dispose();
    super.dispose();
  }
}
