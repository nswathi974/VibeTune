import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart' show LoopMode;
import 'package:youtube_player_flutter/youtube_player_flutter.dart' as yt;
import '../../models/song_model.dart';
import 'playback_adapter.dart';

/// YouTubeAdapter
///
/// Implements policy-compliant embedded playback using YouTube's official
/// IFrame Player. Preserves YouTube's visible viewport, branding, and ads,
/// and aligns positions with VibeTune's synchronized lyrics engine.
class YouTubeAdapter implements PlaybackAdapter {
  yt.YoutubePlayerController? _controller;
  StreamSubscription<yt.YoutubeVideoState>? _videoStateSub;
  StreamSubscription<yt.YoutubePlayerValue>? _valueSub;

  PlaybackEngineState _engineState = PlaybackEngineState.idle;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _volume = 1.0;
  double _speed = 1.0;
  LoopMode _loopMode = LoopMode.off;
  PlaybackMode _playbackMode = PlaybackMode.normal;
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

  // Getters
  yt.YoutubePlayerController? get youtubeController => _controller;

  @override
  PlaybackSourceType get sourceType => PlaybackSourceType.youtube;

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
  bool get hasSecondaryTrack => false;

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

  void _initStreams() {
    _videoStateSub?.cancel();
    _videoStateSub = _controller!.videoStateStream.listen((state) {
      _position = state.position;
      _positionController.add(state.position);
    });

    _valueSub?.cancel();
    _valueSub = _controller!.stream.listen((value) {
      final wasState = _engineState;

      if (value.playerState == yt.PlayerState.playing) {
        _engineState = PlaybackEngineState.playing;
        _errorMessage = null;
      } else if (value.playerState == yt.PlayerState.paused) {
        _engineState = PlaybackEngineState.paused;
      } else if (value.playerState == yt.PlayerState.buffering) {
        _engineState = PlaybackEngineState.loading;
      } else if (value.playerState == yt.PlayerState.ended) {
        _engineState = PlaybackEngineState.completed;
        if (_loopMode == LoopMode.one) {
          seek(Duration.zero);
          _controller?.playVideo();
        } else {
          _completedController.add(null);
        }
      }

      if (value.metaData.duration > Duration.zero &&
          value.metaData.duration != _duration) {
        _duration = value.metaData.duration;
        _durationController.add(_duration);
      }

      if (value.error != yt.YoutubeError.none) {
        _errorMessage = 'YouTube stream error: ${value.error.name}';
        _engineState = PlaybackEngineState.error;
        _errorController.add(_errorMessage);
      }

      if (wasState != _engineState) {
        _stateController.add(_engineState);
      }
    });
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
    _engineState = PlaybackEngineState.loading;
    _stateController.add(_engineState);

    final videoId = song.youtubeVideoId;
    if (videoId == null || videoId.isEmpty) {
      _errorMessage = 'No verified YouTube video ID mapped for this track.';
      _engineState = PlaybackEngineState.error;
      _errorController.add(_errorMessage);
      _stateController.add(_engineState);
      return;
    }

    // Safely tear down any existing controller before creating a new one
    await _disposeControllerOnly();

    try {
      _controller = yt.YoutubePlayerController.fromVideoId(
        videoId: videoId,
        autoPlay: autoPlay,
        params: const yt.YoutubePlayerParams(
          showControls: true,
          showFullscreenButton: false,
          showVideoAnnotations: false,
          mute: false,
        ),
      );
      _initStreams();
    } on Object catch (e) {
      debugPrint('YouTubeAdapter platform controller initialization notice: $e');
    }

    _duration = song.duration;
    _durationController.add(_duration);

    if (initialPosition != null && initialPosition > Duration.zero) {
      _position = initialPosition;
      await seek(initialPosition);
    } else {
      _position = Duration.zero;
    }

    if (autoPlay) {
      _engineState = PlaybackEngineState.playing;
    } else {
      _engineState = PlaybackEngineState.paused;
    }
    _stateController.add(_engineState);
  }

  @override
  Future<void> play() async {
    await _controller?.playVideo();
    _engineState = PlaybackEngineState.playing;
    _stateController.add(_engineState);
  }

  @override
  Future<void> pause() async {
    await _controller?.pauseVideo();
    _engineState = PlaybackEngineState.paused;
    _stateController.add(_engineState);
  }

  @override
  Future<void> stop() async {
    try {
      await _controller?.stopVideo();
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
    await _controller?.seekTo(
      seconds: targetPosition.inMilliseconds / 1000.0,
      allowSeekAhead: true,
    );
  }

  @override
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    await _controller?.setVolume((_volume * 100).round());
  }

  @override
  Future<void> setSpeed(double speed) async {
    _speed = speed.clamp(0.5, 2.0);
    await _controller?.setPlaybackRate(_speed);
  }

  @override
  Future<void> setLoopMode(LoopMode loopMode) async {
    _loopMode = loopMode;
  }

  @override
  Future<void> setPlaybackMode(PlaybackMode mode) async {
    _playbackMode = mode;
    // Honest Sing-Along: YouTube tracks do not have isolated stems.
    // Full audio continues playing without breaking.
  }

  @override
  Future<void> loadDynamicKaraokeStem(
    String stemUrl, {
    required Duration currentPosition,
    required double speed,
    required bool isPlaying,
  }) async {
    // Dynamic stem not supported for external video embeds
    debugPrint('Dynamic karaoke stems not applicable to YouTube embeds');
  }

  Future<void> _disposeControllerOnly() async {
    await _videoStateSub?.cancel();
    _videoStateSub = null;
    await _valueSub?.cancel();
    _valueSub = null;
    try {
      await _controller?.close();
    } catch (e) {
      debugPrint('YouTubeAdapter error closing controller: $e');
    }
    _controller = null;
  }

  @override
  Future<void> dispose() async {
    await _disposeControllerOnly();
    await _positionController.close();
    await _durationController.close();
    await _stateController.close();
    await _errorController.close();
    await _completedController.close();
  }
}
