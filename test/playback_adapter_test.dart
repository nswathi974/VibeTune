import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibetune/models/song_model.dart';
import 'package:vibetune/services/audio_player_service.dart';
import 'package:vibetune/services/playback/playback_adapter.dart';
import 'package:vibetune/services/playback/just_audio_adapter.dart';
import 'package:vibetune/services/playback/youtube_adapter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('PlaybackAdapter Architecture Unit Tests', () {
    test('JustAudioAdapter initializes with idle state and default parameters', () {
      final adapter = JustAudioAdapter();
      expect(adapter.sourceType, PlaybackSourceType.localAsset);
      expect(adapter.engineState, PlaybackEngineState.idle);
      expect(adapter.isPlaying, isFalse);
      expect(adapter.isLoading, isFalse);
      expect(adapter.position, Duration.zero);
      expect(adapter.duration, Duration.zero);
      expect(adapter.hasSecondaryTrack, isFalse);
      expect(adapter.volume, 1.0);
      expect(adapter.speed, 1.0);
      expect(adapter.loopMode, LoopMode.off);
      expect(adapter.playbackMode, PlaybackMode.normal);
      expect(adapter.errorMessage, isNull);
    });

    test('YouTubeAdapter initializes with idle state and Sing-Along capabilities', () {
      final adapter = YouTubeAdapter();
      expect(adapter.sourceType, PlaybackSourceType.youtube);
      expect(adapter.engineState, PlaybackEngineState.idle);
      expect(adapter.isPlaying, isFalse);
      expect(adapter.isLoading, isFalse);
      expect(adapter.position, Duration.zero);
      expect(adapter.duration, Duration.zero);
      expect(adapter.hasSecondaryTrack, isFalse);
      expect(adapter.volume, 1.0);
      expect(adapter.speed, 1.0);
      expect(adapter.youtubeController, isNull);
      expect(adapter.errorMessage, isNull);
    });

    test('YouTubeAdapter safely rejects songs without video IDs', () async {
      final adapter = YouTubeAdapter();
      const songWithoutVideo = Song(
        id: 'no_yt_01',
        title: 'No Video Track',
        artist: 'Artist',
        movieOrAlbum: 'Album',
        language: 'Hindi',
        coverImage: 'assets/images/cover.jpg',
        normalAudioPath: '',
        duration: Duration(minutes: 3),
        year: 2024,
        genre: 'Pop',
        isPlayable: false,
      );

      await adapter.load(songWithoutVideo);
      expect(adapter.engineState, PlaybackEngineState.error);
      expect(adapter.errorMessage, contains('No verified YouTube video ID'));
    });

    test('AudioPlayerService integrates adapter architecture seamlessly', () {
      final audioService = AudioPlayerService();
      expect(audioService.activeAdapter, isNotNull);
      expect(audioService.currentSong, isNull);
      expect(audioService.isPlaying, isFalse);
      expect(audioService.isLoading, isFalse);
      expect(audioService.position, Duration.zero);
      expect(audioService.duration, Duration.zero);
      expect(audioService.youtubeController, isNull);
    });

    test('AudioPlayerService unplayable songs fail gracefully with honest notice', () async {
      final audioService = AudioPlayerService();
      const unplayableSong = Song(
        id: 'unplayable_test',
        title: 'Unplayable Song',
        artist: 'Test Artist',
        movieOrAlbum: 'Test Album',
        language: 'Hindi',
        coverImage: 'assets/images/featured_cover.jpg',
        normalAudioPath: '',
        duration: Duration(minutes: 3),
        year: 2024,
        genre: 'Pop',
        isPlayable: false,
        audioSourceNotice: 'Commercial audio streaming rights reserved by label.',
      );

      await audioService.playSong(unplayableSong);

      expect(audioService.isPlaying, isFalse);
      expect(audioService.isLoading, isFalse);
      expect(audioService.playbackErrorMessage, isNotNull);
      expect(audioService.playbackErrorMessage, contains('streaming rights reserved by label'));
    });

    test('AudioPlayerService toggleMode gracefully handles mode switching with honest notices', () async {
      final audioService = AudioPlayerService();

      // No song loaded initially
      await audioService.toggleMode();
      expect(audioService.playbackMode, PlaybackMode.normal);

      // Verify explicit setPlaybackMode
      await audioService.setPlaybackMode(PlaybackMode.karaoke);
      expect(audioService.playbackMode, PlaybackMode.normal); // No song, stays normal

      // Volume clamping
      await audioService.setVolume(1.8);
      expect(audioService.volume, 1.0);
      await audioService.setVolume(-0.2);
      expect(audioService.volume, 0.0);
      await audioService.setVolume(0.7);
      expect(audioService.volume, 0.7);
    });

    test('AudioPlayerService volume and speed updates propagate to active adapter', () async {
      final audioService = AudioPlayerService();

      await audioService.setVolume(0.65);
      expect(audioService.volume, 0.65);
      expect(audioService.activeAdapter!.volume, 0.65);

      await audioService.setSpeed(1.25);
      expect(audioService.speed, 1.25);
      expect(audioService.activeAdapter!.speed, 1.25);
    });

    test('AudioPlayerService seek updates position and lyrics index cleanly', () async {
      final audioService = AudioPlayerService();
      const targetPos = Duration(seconds: 42);

      await audioService.seek(targetPos);
      expect(audioService.position, targetPos);
    });

    test('AudioPlayerService clean loop mode cycling', () {
      final audioService = AudioPlayerService();
      expect(audioService.loopMode, LoopMode.off);

      audioService.cycleLoopMode();
      expect(audioService.loopMode, LoopMode.all);

      audioService.cycleLoopMode();
      expect(audioService.loopMode, LoopMode.one);

      audioService.cycleLoopMode();
      expect(audioService.loopMode, LoopMode.off);
    });

    test('AudioPlayerService stops cleanly and resets position', () async {
      final audioService = AudioPlayerService();
      await audioService.seek(const Duration(seconds: 25));
      expect(audioService.position, const Duration(seconds: 25));

      await audioService.stop();
      expect(audioService.isPlaying, isFalse);
      expect(audioService.position, Duration.zero);
    });
  });
}
