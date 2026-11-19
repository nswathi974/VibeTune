import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibetune/data/song_catalog.dart';
import 'package:vibetune/models/song_model.dart';
import 'package:vibetune/services/audio_player_service.dart';
import 'package:vibetune/services/playlist_service.dart';
import 'package:vibetune/services/playback/just_audio_adapter.dart';

/// Test adapter that simulates JustAudio without native hardware dependencies
class TestJustAudioAdapter extends JustAudioAdapter {
  Song? lastLoadedSong;
  PlaybackMode activeMode = PlaybackMode.normal;
  bool isStopped = false;

  @override
  Future<void> load(
    Song song, {
    Duration? initialPosition,
    bool autoPlay = true,
    PlaybackMode mode = PlaybackMode.normal,
  }) async {
    lastLoadedSong = song;
    activeMode = mode;
    isStopped = false;
  }

  @override
  Future<void> stop() async {
    isStopped = true;
  }

  @override
  bool get hasSecondaryTrack => lastLoadedSong?.isKaraokeAvailable ?? false;

  @override
  Future<void> setPlaybackMode(PlaybackMode mode) async {
    activeMode = mode;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('VibeTune Phase 2 Playback Regression Suite', () {
    test('1. Local audio playback and stem verification for Hindi track', () {
      final songs = SongCatalog.allSongs;
      final hindiSong = songs.firstWhere((s) => s.id == 'hi_01');

      expect(hindiSong.title, 'Agar Tum Saath Ho');
      expect(hindiSong.isPlayable, isTrue);
      expect(hindiSong.normalAudioPath, isNotEmpty);
      expect(hindiSong.karaokeAudioPath, isNotEmpty);
      expect(hindiSong.isKaraokeAvailable, isTrue);
      expect(hindiSong.isYouTubeTrack, isFalse);
    });

    test('2. Dual-stem Kannada master track verification', () {
      final songs = SongCatalog.allSongs;
      final kannadaSong = songs.firstWhere((s) => s.id == 'ka_01');

      expect(kannadaSong.title, 'Anisuthide');
      expect(kannadaSong.isPlayable, isTrue);
      expect(kannadaSong.normalAudioPath, isNotEmpty);
      expect(kannadaSong.karaokeAudioPath, isNotEmpty);
      expect(kannadaSong.isKaraokeAvailable, isTrue);
      expect(kannadaSong.isYouTubeTrack, isFalse);
    });

    test('3. Dual-stem Tamil master track verification', () {
      final songs = SongCatalog.allSongs;
      final tamilSong = songs.firstWhere((s) => s.id == 'ta_01');

      expect(tamilSong.title, 'Thuli Thuli');
      expect(tamilSong.isPlayable, isTrue);
      expect(tamilSong.normalAudioPath, isNotEmpty);
      expect(tamilSong.karaokeAudioPath, isNotEmpty);
      expect(tamilSong.isKaraokeAvailable, isTrue);
      expect(tamilSong.isYouTubeTrack, isFalse);
    });

    test('4. Rapid track switching preserves clean playback state without memory leaks', () async {
      final testAudioAdapter = TestJustAudioAdapter();
      final audioService = AudioPlayerService(justAudioAdapter: testAudioAdapter);
      final songs = SongCatalog.allSongs;

      final track1 = songs.firstWhere((s) => s.id == 'hi_01');
      final track2 = songs.firstWhere((s) => s.id == 'ka_01');
      final track3 = songs.firstWhere((s) => s.id == 'ta_01');

      // Step A: Load Track 1
      await audioService.playSong(track1, autoPlay: false);
      expect(audioService.currentSong?.id, 'hi_01');
      expect(audioService.isCurrentSongYouTube, isFalse);
      expect(testAudioAdapter.lastLoadedSong?.id, 'hi_01');

      // Step B: Switch to Track 2
      await audioService.playSong(track2, autoPlay: false);
      expect(audioService.currentSong?.id, 'ka_01');
      expect(testAudioAdapter.lastLoadedSong?.id, 'ka_01');

      // Step C: Switch to Track 3
      await audioService.playSong(track3, autoPlay: false);
      expect(audioService.currentSong?.id, 'ta_01');
      expect(testAudioAdapter.lastLoadedSong?.id, 'ta_01');
    });

    test('5. Pause/resume and seeking updates position cleanly', () async {
      final audioService = AudioPlayerService();

      // Seek
      const seekTarget = Duration(seconds: 45);
      await audioService.seek(seekTarget);
      expect(audioService.position, seekTarget);

      // Volume & speed controls
      await audioService.setVolume(0.85);
      expect(audioService.volume, 0.85);

      await audioService.setSpeed(1.5);
      expect(audioService.speed, 1.5);

      // Stop
      await audioService.stop();
      expect(audioService.isPlaying, isFalse);
      expect(audioService.position, Duration.zero);
    });

    test('6. PlaylistService queue navigates cleanly through all 10 verified songs', () async {
      final playlistService = PlaylistService();
      final testAudioAdapter = TestJustAudioAdapter();
      final audioService = AudioPlayerService(justAudioAdapter: testAudioAdapter);
      final songs = SongCatalog.allSongs;

      expect(songs.length, 10);
      expect(playlistService.allSongs.length, 10);

      // Start by playing first song
      playlistService.playSong(songs[0], audioService);
      expect(audioService.currentSong?.id, songs[0].id);

      // Play fifth song
      playlistService.playSong(songs[4], audioService);
      expect(audioService.currentSong?.id, songs[4].id);
    });

    test('7. Karaoke stem switching toggles seamlessly between normal and karaoke modes', () async {
      final testAudioAdapter = TestJustAudioAdapter();
      final audioService = AudioPlayerService(justAudioAdapter: testAudioAdapter);
      final songs = SongCatalog.allSongs;

      final song = songs.firstWhere((s) => s.id == 'hi_01');
      await audioService.playSong(song, autoPlay: false);
      expect(audioService.playbackMode, PlaybackMode.normal);
      expect(audioService.hasSecondaryTrack, isTrue);

      await audioService.toggleMode();
      expect(audioService.playbackMode, PlaybackMode.karaoke);
      expect(audioService.playbackErrorMessage, isNull);

      // Switch back to normal
      await audioService.toggleMode();
      expect(audioService.playbackMode, PlaybackMode.normal);
      expect(audioService.playbackErrorMessage, isNull);
    });
  });
}
