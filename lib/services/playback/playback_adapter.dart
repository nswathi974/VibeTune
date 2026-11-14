import 'dart:async';
import 'package:just_audio/just_audio.dart' show LoopMode;
import '../../models/song_model.dart';

/// Supported underlying playback audio source categories
enum PlaybackSourceType {
  localAsset,
  archiveStream,
  youtube,
  none,
}

/// Normalized playback engine states across all providers
enum PlaybackEngineState {
  idle,
  loading,
  playing,
  paused,
  completed,
  error,
}

/// Abstract contract for unified audio and video playback engines in VibeTune.
/// Ensures identical behavior across local multi-track audio, Archive.org streams,
/// and official embedded YouTube player streams.
abstract class PlaybackAdapter {
  /// The audio source type handled by this adapter
  PlaybackSourceType get sourceType;

  /// Normalized engine state
  PlaybackEngineState get engineState;

  /// Current playback position
  Duration get position;

  /// Total duration of the loaded track
  Duration get duration;

  /// Whether audio/video is actively playing
  bool get isPlaying;

  /// Whether media is actively loading or buffering
  bool get isLoading;

  /// Error message if playback failed, null otherwise
  String? get errorMessage;

  /// Whether a true secondary instrumental stem is available and synchronized
  bool get hasSecondaryTrack;

  /// Active playback mode (Normal Vocals vs Karaoke Instrumental)
  PlaybackMode get playbackMode;

  /// Active volume (0.0 to 1.0)
  double get volume;

  /// Active playback speed (0.5x to 2.0x)
  double get speed;

  /// Active loop/repeat mode
  LoopMode get loopMode;

  /// Continuous stream of playback timestamps
  Stream<Duration> get positionStream;

  /// Continuous stream of track duration
  Stream<Duration> get durationStream;

  /// Continuous stream of engine state transitions
  Stream<PlaybackEngineState> get stateStream;

  /// Stream emitting errors encountered by the underlying engine
  Stream<String?> get errorStream;

  /// Stream fired when track finishes playing
  Stream<void> get onCompletedStream;

  /// Loads and prepares the given song for playback
  Future<void> load(
    Song song, {
    Duration? initialPosition,
    bool autoPlay = true,
    PlaybackMode mode = PlaybackMode.normal,
  });

  /// Starts or resumes playback
  Future<void> play();

  /// Pauses active playback
  Future<void> pause();

  /// Stops playback and resets position
  Future<void> stop();

  /// Seeks to the specified position
  Future<void> seek(Duration targetPosition);

  /// Sets audio volume (0.0 to 1.0)
  Future<void> setVolume(double volume);

  /// Sets playback rate (0.5x to 2.0x)
  Future<void> setSpeed(double speed);

  /// Sets the loop mode (off, all, one)
  Future<void> setLoopMode(LoopMode loopMode);

  /// Switches mode between Normal (vocals) and Karaoke (instrumental)
  Future<void> setPlaybackMode(PlaybackMode mode);

  /// Dynamically loads an AI separated instrumental stem
  Future<void> loadDynamicKaraokeStem(
    String stemUrl, {
    required Duration currentPosition,
    required double speed,
    required bool isPlaying,
  });

  /// Completely releases and disposes the underlying engine and subscriptions
  Future<void> dispose();
}
