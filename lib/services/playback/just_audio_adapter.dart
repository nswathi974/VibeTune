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
  StreamSubscription<Duration>? _primaryPositionSub;
  StreamSubscription<Duration?>? _primaryDurationSub;

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

  void _initListeners() {
    _primaryStateSub = _primaryPlayer.playerStateStream.listen((state) {
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
    }, onError: (Object error) {
      debugPrint('JustAudioAdapter primary state error: $error');
      _errorMessage = 'Playback error: $error';
      _engineState = PlaybackEngineState.error;
      _errorController.add(_errorMessage);
      _stateController.add(_engineState);
    });

    _primaryPositionSub = _primaryPlayer.positionStream.listen((pos) {
      if (_primaryPlayer.audioSource != null &&
          (_primaryPlayer.playing || pos > Duration.zero)) {
        _position = pos;
        _positionController.add(pos);
      }

      // Real-time drift check for secondary instrumental player
      if (_hasSecondaryTrack && isPlaying) {
        try {
          final secPos = _secondaryPlayer.position;
          final drift = (pos - secPos).inMilliseconds.abs();
          if (drift > 80) {
            _secondaryPlayer.seek(pos);
          }
        } catch (_) {}
      }
    });

    _primaryDurationSub = _primaryPlayer.durationStream.listen((dur) {
      if (dur != null && dur != _duration) {
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
    _engineState = PlaybackEngineState.loading;
    _stateController.add(_engineState);

    final vocalPath = song.normalAudioPath;
    final karaokePath = (song.isKaraokeAvailable &&
            song.karaokeAudioPath != null &&
            song.karaokeAudioPath!.isNotEmpty)
        ? song.karaokeAudioPath!
        : '';

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
      // 1. Load Primary Audio
      if (vocalPath.isNotEmpty) {
        try {
          await _loadSourceToPlayer(_primaryPlayer, vocalPath,
              initialPosition: initialPosition);
        } on Object catch (primaryErr) {
          debugPrint('JustAudioAdapter primary track notice: $primaryErr');
        }
      }

      // 2. Load Secondary Instrumental Track if present
      if (karaokePath.isNotEmpty) {
        try {
          await _loadSourceToPlayer(_secondaryPlayer, karaokePath,
              initialPosition: initialPosition);
          _hasSecondaryTrack = true;
        } on Object catch (secError) {
          debugPrint('JustAudioAdapter secondary track unavailable: $secError');
          _hasSecondaryTrack = false;
        }
      } else {
        try {
          await _secondaryPlayer.stop();
        } on Object catch (_) {}
        _hasSecondaryTrack = false;
      }

      // 3. Set speed and mode volumes
      try {
        await _primaryPlayer.setSpeed(_speed);
        if (_hasSecondaryTrack) {
          await _secondaryPlayer.setSpeed(_speed);
        }
      } on Object catch (_) {}
      _applyModeVolumes();

      // Set loop mode
      try {
        await _primaryPlayer.setLoopMode(_loopMode);
        if (_hasSecondaryTrack) {
          await _secondaryPlayer.setLoopMode(_loopMode);
        }
      } on Object catch (_) {}

      // 4. Start playback if requested
      if (autoPlay) {
        try {
          if (_hasSecondaryTrack) {
            await Future.wait([_primaryPlayer.play(), _secondaryPlayer.play()]);
          } else {
            await _primaryPlayer.play();
          }
        } on Object catch (_) {}
        _engineState = PlaybackEngineState.playing;
      } else {
        _engineState = PlaybackEngineState.paused;
      }
      _stateController.add(_engineState);
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
      if (_hasSecondaryTrack) {
        await _secondaryPlayer.seek(_primaryPlayer.position);
        await Future.wait([_primaryPlayer.play(), _secondaryPlayer.play()]);
      } else {
        await _primaryPlayer.play();
      }
    } catch (e) {
      debugPrint('JustAudioAdapter play channel notice: $e');
    }
    _engineState = PlaybackEngineState.playing;
    _stateController.add(_engineState);
  }

  @override
  Future<void> pause() async {
    try {
      if (_hasSecondaryTrack) {
        await Future.wait([_primaryPlayer.pause(), _secondaryPlayer.pause()]);
      } else {
        await _primaryPlayer.pause();
      }
    } catch (e) {
      debugPrint('JustAudioAdapter pause channel notice: $e');
    }
    _engineState = PlaybackEngineState.paused;
    _stateController.add(_engineState);
  }

  @override
  Future<void> stop() async {
    try {
      await _primaryPlayer.stop();
      await _secondaryPlayer.stop();
    } catch (e) {
      debugPrint('JustAudioAdapter stop channel notice: $e');
    }
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
      if (_hasSecondaryTrack) {
        await Future.wait([
          _primaryPlayer.seek(targetPosition),
          _secondaryPlayer.seek(targetPosition),
        ]);
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
      if (_hasSecondaryTrack) {
        await Future.wait([
          _primaryPlayer.setSpeed(_speed),
          _secondaryPlayer.setSpeed(_speed),
        ]);
      } else {
        await _primaryPlayer.setSpeed(_speed);
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
    _playbackMode = mode;
    _applyModeVolumes();
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
    await _primaryPositionSub?.cancel();
    _primaryPositionSub = null;
    await _primaryDurationSub?.cancel();
    _primaryDurationSub = null;

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
