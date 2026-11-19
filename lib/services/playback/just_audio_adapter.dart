import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../../models/song_model.dart';
import 'playback_adapter.dart';

/// JustAudioAdapter
///
/// Implements high-fidelity playback with synchronized dual-player architecture
/// for local assets (MP3, WAV) and Archive.org progressive HTTP audio streams.
/// Supports zero-latency switching between vocal tracks and true instrumental stems.
class JustAudioAdapter implements PlaybackAdapter {
  final AudioPlayer _primaryPlayer;
  final AudioPlayer _secondaryPlayer;

  bool _hasSecondaryTrack = false;
  bool _isSecondaryLoaded = false;
  String _currentVocalPath = '';
  String _currentKaraokePath = '';
  PlaybackMode _playbackMode = PlaybackMode.normal;
  PlaybackSourceType _sourceType = PlaybackSourceType.localAsset;
  PlaybackEngineState _engineState = PlaybackEngineState.idle;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _volume = 1.0;
  double _speed = 1.0;
  LoopMode _loopMode = LoopMode.off;
  String? _errorMessage;

  // Stream Controllers
  final StreamController<Duration> _positionController =
      StreamController<Duration>.broadcast();
  final StreamController<Duration> _durationController =
      StreamController<Duration>.broadcast();
  final StreamController<PlaybackEngineState> _stateController =
      StreamController<PlaybackEngineState>.broadcast();
  final StreamController<String?> _errorController =
      StreamController<String?>.broadcast();
  final StreamController<void> _completedController =
      StreamController<void>.broadcast();

  // Subscriptions
  StreamSubscription<PlayerState>? _primaryStateSub;
  StreamSubscription<PlayerState>? _secondaryStateSub;
  StreamSubscription<Duration>? _primaryPositionSub;
  StreamSubscription<Duration>? _secondaryPositionSub;
  StreamSubscription<Duration?>? _primaryDurationSub;
  StreamSubscription<Duration?>? _secondaryDurationSub;

  JustAudioAdapter({AudioPlayer? primary, AudioPlayer? secondary})
      : _primaryPlayer = primary ?? AudioPlayer(),
        _secondaryPlayer = secondary ?? AudioPlayer() {
    _initListeners();
  }

  // Getters
  AudioPlayer get primaryPlayer => _primaryPlayer;
  AudioPlayer get secondaryPlayer => _secondaryPlayer;

  @override
  PlaybackSourceType get sourceType => _sourceType;

  @override
  PlaybackEngineState get engineState => _engineState;

  @override
  Duration get position => _position;

  @override
  Duration get duration => _duration;

  @override
  bool get isPlaying =>
      _engineState == PlaybackEngineState.playing;

  @override
  bool get isLoading =>
      _engineState == PlaybackEngineState.loading;

  @override
  String? get errorMessage => _errorMessage;

  @override
  bool get hasSecondaryTrack => _hasSecondaryTrack;

  @override
  PlaybackMode get playbackMode => _playbackMode;

  @override
  double get volume => _volume;

  @override
  double get speed => _speed;

  @override
  LoopMode get loopMode => _loopMode;

  @override
  Stream<Duration> get positionStream => _positionController.stream;

  @override
  Stream<Duration> get durationStream => _durationController.stream;

  @override
  Stream<PlaybackEngineState> get stateStream => _stateController.stream;

  @override
  Stream<String?> get errorStream => _errorController.stream;

  @override
  Stream<void> get onCompletedStream => _completedController.stream;

  void _handleStateChange(PlayerState state) {
    final wasState = _engineState;
    if (state.processingState == ProcessingState.loading ||
        state.processingState == ProcessingState.buffering) {
      _engineState = PlaybackEngineState.loading;
    } else if (state.processingState == ProcessingState.completed) {
      _engineState = PlaybackEngineState.completed;
      _completedController.add(null);
    } else if (state.playing) {
      _engineState = PlaybackEngineState.playing;
    } else {
      _engineState = PlaybackEngineState.paused;
    }

    if (wasState != _engineState) {
      _stateController.add(_engineState);
    }
  }

  void _initListeners() {
    _primaryStateSub = _primaryPlayer.playerStateStream.listen((state) {
      if (_playbackMode == PlaybackMode.normal) {
        _handleStateChange(state);
      }
    }, onError: (Object error) {
      debugPrint('JustAudioAdapter primary state error: $error');
      _errorMessage = 'Playback error: $error';
      _engineState = PlaybackEngineState.error;
      _errorController.add(_errorMessage);
      _stateController.add(_engineState);
    });

    _secondaryStateSub = _secondaryPlayer.playerStateStream.listen((state) {
      if (_playbackMode == PlaybackMode.karaoke) {
        _handleStateChange(state);
      }
    }, onError: (Object error) {
      debugPrint('JustAudioAdapter secondary state error: $error');
    });

    _primaryPositionSub = _primaryPlayer.positionStream.listen((pos) {
      if (_playbackMode == PlaybackMode.normal &&
          _primaryPlayer.audioSource != null &&
          (_primaryPlayer.playing || pos > Duration.zero)) {
        _position = pos;
        _positionController.add(pos);
      }
    });

    _secondaryPositionSub = _secondaryPlayer.positionStream.listen((pos) {
      if (_playbackMode == PlaybackMode.karaoke &&
          _secondaryPlayer.audioSource != null &&
          (_secondaryPlayer.playing || pos > Duration.zero)) {
        _position = pos;
        _positionController.add(pos);
      }
    });

    _primaryDurationSub = _primaryPlayer.durationStream.listen((dur) {
      if (_playbackMode == PlaybackMode.normal && dur != null && dur != _duration) {
        _duration = dur;
        _durationController.add(dur);
      }
    });

    _secondaryDurationSub = _secondaryPlayer.durationStream.listen((dur) {
      if (_playbackMode == PlaybackMode.karaoke && dur != null && dur != _duration) {
        _duration = dur;
        _durationController.add(dur);
      }
    });
  }

  void _applyModeVolumes() {
    try {
      if (_playbackMode == PlaybackMode.normal) {
        _primaryPlayer.setVolume(_volume);
        if (_hasSecondaryTrack) {
          _secondaryPlayer.setVolume(0.0);
        }
      } else {
        // Karaoke Mode
        if (_hasSecondaryTrack) {
          _primaryPlayer.setVolume(0.0);
          _secondaryPlayer.setVolume(_volume);
        } else {
          // Honest Sing-Along: keep vocal track playing so user can sing along
          _primaryPlayer.setVolume(_volume);
          _secondaryPlayer.setVolume(0.0);
        }
      }
    } on Object catch (e) {
      debugPrint('JustAudioAdapter volume channel notice: $e');
    }
  }

  Future<void> _loadSourceToPlayer(
    AudioPlayer player,
    String path, {
    Duration? initialPosition,
  }) async {
    try {
      if (path.startsWith('http://') || path.startsWith('https://')) {
        await player.setUrl(path, initialPosition: initialPosition);
      } else if (path.startsWith('file://')) {
        await player.setFilePath(path.replaceFirst('file://', ''),
            initialPosition: initialPosition);
      } else {
        await player.setAsset(path, initialPosition: initialPosition);
      }
    } on Object catch (e) {
      debugPrint('JustAudioAdapter _loadSourceToPlayer channel notice: $e');
    }
  }

  @override
  Future<void> load(
    Song song, {
    Duration? initialPosition,
    bool autoPlay = true,
    PlaybackMode mode = PlaybackMode.normal,
  }) async {
    _playbackMode = mode;
    _errorMessage = null;
    _errorController.add(null);
    _hasSecondaryTrack = false;
    _isSecondaryLoaded = false;
    _engineState = PlaybackEngineState.loading;
    _stateController.add(_engineState);

    // CRITICAL: Stop previous playback immediately so browser audio elements
    // are completely halted and do not collide with new source loads
    try {
      await _primaryPlayer.stop();
    } catch (_) {}
    try {
      await _secondaryPlayer.stop();
    } catch (_) {}

    final vocalPath = song.normalAudioPath;
    final karaokePath = (song.isKaraokeAvailable &&
            song.karaokeAudioPath != null &&
            song.karaokeAudioPath!.isNotEmpty)
        ? song.karaokeAudioPath!
        : '';

    _currentVocalPath = vocalPath;
    _currentKaraokePath = karaokePath;
    _hasSecondaryTrack = karaokePath.isNotEmpty;

    _sourceType = vocalPath.startsWith('http://') || vocalPath.startsWith('https://')
        ? PlaybackSourceType.archiveStream
        : PlaybackSourceType.localAsset;

    if (vocalPath.isEmpty && karaokePath.isEmpty) {
      _errorMessage =
          song.audioSourceNotice ?? 'Streaming license required for this track.';
      _engineState = PlaybackEngineState.error;
      _errorController.add(_errorMessage);
      _stateController.add(_engineState);
      return;
    }

    try {
      if (_playbackMode == PlaybackMode.karaoke && _hasSecondaryTrack) {
        // Karaoke Mode: Load and play secondary instrumental stem immediately
        await _loadSourceToPlayer(_secondaryPlayer, karaokePath,
            initialPosition: initialPosition);
        _isSecondaryLoaded = true;

        try {
          await _secondaryPlayer.setSpeed(_speed);
          await _secondaryPlayer.setLoopMode(_loopMode);
          await _secondaryPlayer.setVolume(_volume);
        } catch (_) {}

        if (autoPlay) {
          try {
            await _secondaryPlayer.play();
          } catch (e) {
            debugPrint('JustAudioAdapter karaoke autoPlay notice: $e');
          }
          _engineState = PlaybackEngineState.playing;
        } else {
          _engineState = PlaybackEngineState.paused;
        }
        _stateController.add(_engineState);

        // Preload primary vocal track in background (non-blocking)
        if (vocalPath.isNotEmpty) {
          _loadSourceToPlayer(_primaryPlayer, vocalPath, initialPosition: initialPosition)
              .then((_) {
            _primaryPlayer.setVolume(0.0);
          }).catchError((e) {
            debugPrint('Background vocal preload notice: $e');
          });
        }
      } else {
        // Normal Mode: Load and play primary vocal track immediately!
        // No waiting for secondary track to download - instant playback response!
        await _loadSourceToPlayer(_primaryPlayer, vocalPath,
            initialPosition: initialPosition);

        try {
          await _primaryPlayer.setSpeed(_speed);
          await _primaryPlayer.setLoopMode(_loopMode);
          await _primaryPlayer.setVolume(_volume);
        } catch (_) {}

        if (autoPlay) {
          try {
            await _primaryPlayer.play();
          } catch (e) {
            debugPrint('JustAudioAdapter primary autoPlay notice: $e');
          }
          _engineState = PlaybackEngineState.playing;
        } else {
          _engineState = PlaybackEngineState.paused;
        }
        _stateController.add(_engineState);

        // Preload secondary instrumental stem in background (non-blocking)
        if (karaokePath.isNotEmpty) {
          _loadSourceToPlayer(_secondaryPlayer, karaokePath, initialPosition: initialPosition)
              .then((_) {
            _isSecondaryLoaded = true;
            _secondaryPlayer.setVolume(0.0);
          }).catchError((e) {
            debugPrint('Background karaoke preload notice: $e');
          });
        }
      }
    } on Object catch (e) {
      debugPrint('JustAudioAdapter error loading "$vocalPath": $e');
      _errorMessage = 'Unable to play audio: $e';
      _engineState = PlaybackEngineState.error;
      _errorController.add(_errorMessage);
      _stateController.add(_engineState);
    }
  }

  @override
  Future<void> play() async {
    try {
      if (_playbackMode == PlaybackMode.karaoke && _hasSecondaryTrack) {
        await _secondaryPlayer.play();
      } else {
        await _primaryPlayer.play();
      }
      _engineState = PlaybackEngineState.playing;
    } catch (e) {
      debugPrint('JustAudioAdapter play channel notice: $e');
    }
    _stateController.add(_engineState);
  }

  @override
  Future<void> pause() async {
    try {
      await _primaryPlayer.pause();
    } catch (_) {}
    try {
      await _secondaryPlayer.pause();
    } catch (_) {}
    _engineState = PlaybackEngineState.paused;
    _stateController.add(_engineState);
  }

  @override
  Future<void> stop() async {
    try {
      await _primaryPlayer.stop();
    } catch (_) {}
    try {
      await _secondaryPlayer.stop();
    } catch (_) {}
    _position = Duration.zero;
    _engineState = PlaybackEngineState.idle;
    _stateController.add(_engineState);
    _positionController.add(Duration.zero);
  }

  @override
  Future<void> seek(Duration targetPosition) async {
    _position = targetPosition;
    _positionController.add(targetPosition);

    try {
      if (_playbackMode == PlaybackMode.karaoke && _hasSecondaryTrack) {
        await _secondaryPlayer.seek(targetPosition);
      } else {
        await _primaryPlayer.seek(targetPosition);
      }
    } catch (e) {
      debugPrint('JustAudioAdapter seek channel notice: $e');
    }
  }

  @override
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    _applyModeVolumes();
  }

  @override
  Future<void> setSpeed(double speed) async {
    _speed = speed.clamp(0.5, 2.0);
    try {
      await _primaryPlayer.setSpeed(_speed);
      if (_hasSecondaryTrack) {
        await _secondaryPlayer.setSpeed(_speed);
      }
    } catch (e) {
      debugPrint('JustAudioAdapter speed channel notice: $e');
    }
  }

  @override
  Future<void> setLoopMode(LoopMode loopMode) async {
    _loopMode = loopMode;
    try {
      await _primaryPlayer.setLoopMode(_loopMode);
      if (_hasSecondaryTrack) {
        await _secondaryPlayer.setLoopMode(_loopMode);
      }
    } catch (e) {
      debugPrint('JustAudioAdapter loopMode channel notice: $e');
    }
  }

  @override
  Future<void> setPlaybackMode(PlaybackMode mode) async {
    if (_playbackMode == mode) return;
    _playbackMode = mode;

    if (mode == PlaybackMode.karaoke && _hasSecondaryTrack) {
      final currentPos = _primaryPlayer.position;
      try {
        await _primaryPlayer.pause();
      } catch (_) {}

      if (!_isSecondaryLoaded && _currentKaraokePath.isNotEmpty) {
        await _loadSourceToPlayer(_secondaryPlayer, _currentKaraokePath, initialPosition: currentPos);
        _isSecondaryLoaded = true;
      }

      try {
        await _secondaryPlayer.seek(currentPos);
        await _secondaryPlayer.setVolume(_volume);
        await _primaryPlayer.setVolume(0.0);
        if (_engineState == PlaybackEngineState.playing) {
          await _secondaryPlayer.play();
        }
      } catch (e) {
        debugPrint('JustAudioAdapter mode switch to karaoke error: $e');
      }
    } else {
      final currentPos = _secondaryPlayer.position;
      try {
        await _secondaryPlayer.pause();
      } catch (_) {}

      try {
        await _primaryPlayer.seek(currentPos);
        await _primaryPlayer.setVolume(_volume);
        await _secondaryPlayer.setVolume(0.0);
        if (_engineState == PlaybackEngineState.playing) {
          await _primaryPlayer.play();
        }
      } catch (e) {
        debugPrint('JustAudioAdapter mode switch to normal error: $e');
      }
    }
  }

  @override
  Future<void> loadDynamicKaraokeStem(
    String stemUrl, {
    required Duration currentPosition,
    required double speed,
    required bool isPlaying,
  }) async {
    try {
      await _loadSourceToPlayer(_secondaryPlayer, stemUrl,
          initialPosition: currentPosition);
      _hasSecondaryTrack = true;
      await _secondaryPlayer.setSpeed(speed);
      if (isPlaying) {
        await _secondaryPlayer.play();
      }
    } catch (e) {
      debugPrint('JustAudioAdapter dynamic stem channel notice: $e');
    }
    _playbackMode = PlaybackMode.karaoke;
    _applyModeVolumes();
  }

  @override
  Future<void> dispose() async {
    await _primaryStateSub?.cancel();
    _primaryStateSub = null;
    await _secondaryStateSub?.cancel();
    _secondaryStateSub = null;
    await _primaryPositionSub?.cancel();
    _primaryPositionSub = null;
    await _secondaryPositionSub?.cancel();
    _secondaryPositionSub = null;
    await _primaryDurationSub?.cancel();
    _primaryDurationSub = null;
    await _secondaryDurationSub?.cancel();
    _secondaryDurationSub = null;

    try {
      await _primaryPlayer.dispose();
      await _secondaryPlayer.dispose();
    } catch (_) {}

    await _positionController.close();
    await _durationController.close();
    await _stateController.close();
    await _errorController.close();
    await _completedController.close();
  }
}
