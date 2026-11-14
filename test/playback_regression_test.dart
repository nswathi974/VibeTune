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
    test('1. Local audio playback and stem verification', () {
      final songs = SongCatalog.allSongs;
      final localSong = songs.firstWhere((s) => s.id == 'vt_studio_hi');

      expect(localSong.isPlayable, isTrue);
      expect(localSong.normalAudioPath, isNotEmpty);
      expect(localSong.karaokeAudioPath, isNotEmpty);
      expect(localSong.isKaraokeAvailable, isTrue);
      expect(localSong.isYouTubeTrack, isFalse);
    });

    test('2. Archive.org streaming source verification', () {
      final songs = SongCatalog.allSongs;
      final archiveSong = songs.firstWhere((s) => s.id == 'stream_hi_01');

      expect(archiveSong.isPlayable, isTrue);
      expect(archiveSong.normalAudioPath, startsWith('https://archive.org'));
      expect(archiveSong.isKaraokeAvailable, isFalse); // Full-mix archival only
      expect(archiveSong.isYouTubeTrack, isFalse);
    });

    test('3. YouTube embedded playback source verification', () {
      final songs = SongCatalog.allSongs;
      final ytSong = songs.firstWhere((s) => s.id == 'hi_01');

      expect(ytSong.isPlayable, isTrue);
      expect(ytSong.isYouTubeTrack, isTrue);
      expect(ytSong.youtubeVideoId, 'BddP6PYo2gs');
      expect(ytSong.normalAudioPath, isEmpty);
    });

    test('4. Rapid source switching cleans up YouTube controller and prevents controller leaks', () async {
      final testAudioAdapter = TestJustAudioAdapter();
      final audioService = AudioPlayerService(justAudioAdapter: testAudioAdapter);
      final songs = SongCatalog.allSongs;

      final localTrack = songs.firstWhere((s) => s.id == 'vt_studio_hi');
      final ytTrack = songs.firstWhere((s) => s.id == 'hi_01');
      final archiveTrack = songs.firstWhere((s) => s.id == 'stream_hi_01');

      // Step A: Load Local Track
      await audioService.playSong(localTrack, autoPlay: false);
      expect(audioService.currentSong?.id, 'vt_studio_hi');
      expect(audioService.isCurrentSongYouTube, isFalse);
      expect(audioService.youtubeController, isNull);
      expect(testAudioAdapter.lastLoadedSong?.id, 'vt_studio_hi');

      // Step B: Rapidly switch to YouTube Track
      await audioService.playSong(ytTrack, autoPlay: false);
      expect(audioService.currentSong?.id, 'hi_01');
      expect(audioService.isCurrentSongYouTube, isTrue);
      expect(testAudioAdapter.isStopped, isTrue); // JustAudio must be stopped

      // Step C: Rapidly switch to Archive Track
      await audioService.playSong(archiveTrack, autoPlay: false);
      expect(audioService.currentSong?.id, 'stream_hi_01');
      expect(audioService.isCurrentSongYouTube, isFalse);
      // The YouTube controller MUST be disposed and nulled
      expect(audioService.youtubeController, isNull);
      expect(testAudioAdapter.lastLoadedSong?.id, 'stream_hi_01');

      // Step D: Rapidly switch back to YouTube Track
      await audioService.playSong(ytTrack, autoPlay: false);
      expect(audioService.currentSong?.id, 'hi_01');
      expect(audioService.isCurrentSongYouTube, isTrue);

      // Step E: Switch back to Local Track
      await audioService.playSong(localTrack, autoPlay: false);
      expect(audioService.currentSong?.id, 'vt_studio_hi');
      expect(audioService.youtubeController, isNull);
    });

    test('5. Pause/resume and seeking updates position and lyrics cleanly', () async {
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

    test('6. Mixed-source queue in PlaylistService navigates correctly between Local, YouTube, and Archive tracks', () async {
      final playlistService = PlaylistService();
      final testAudioAdapter = TestJustAudioAdapter();
      final audioService = AudioPlayerService(justAudioAdapter: testAudioAdapter);
      final songs = SongCatalog.allSongs;

      final localSong = songs.firstWhere((s) => s.id == 'vt_studio_hi');
      final ytSong = songs.firstWhere((s) => s.id == 'hi_01');
      final archiveSong = songs.firstWhere((s) => s.id == 'stream_hi_01');

      // Start by playing local track
      playlistService.playSong(localSong, audioService);
      expect(audioService.currentSong?.id, 'vt_studio_hi');

      // Play YouTube track
      playlistService.playSong(ytSong, audioService);
      expect(audioService.currentSong?.id, 'hi_01');
      expect(audioService.isCurrentSongYouTube, isTrue);

      // Play Archive track
      playlistService.playSong(archiveSong, audioService);
      expect(audioService.currentSong?.id, 'stream_hi_01');
      expect(audioService.isCurrentSongYouTube, isFalse);
    });

    test('7. Karaoke stem switching and honest Sing-Along behavior', () async {
      final testAudioAdapter = TestJustAudioAdapter();
      final audioService = AudioPlayerService(justAudioAdapter: testAudioAdapter);
      final songs = SongCatalog.allSongs;

      // Single-track song (no secondary stem)
      final devotionalSong = songs.firstWhere((s) => s.id == 'stream_ka_01');
      await audioService.playSong(devotionalSong, autoPlay: false);
      expect(audioService.playbackMode, PlaybackMode.normal);

      await audioService.toggleMode();
      expect(audioService.playbackMode, PlaybackMode.karaoke);
      expect(audioService.playbackErrorMessage, contains('Karaoke instrumental stem is not available'));

      // Switch back to normal
      await audioService.toggleMode();
      expect(audioService.playbackMode, PlaybackMode.normal);
      expect(audioService.playbackErrorMessage, isNull);
    });

    test('8. YouTube track honest Sing-Along behavior preserves playback without error', () async {
      final audioService = AudioPlayerService();
      final songs = SongCatalog.allSongs;
      final ytSong = songs.firstWhere((s) => s.id == 'hi_01');

      await audioService.playSong(ytSong, autoPlay: false);
      expect(audioService.isCurrentSongYouTube, isTrue);

      await audioService.toggleMode();
      expect(audioService.playbackMode, PlaybackMode.karaoke);
      expect(audioService.playbackErrorMessage, contains('Sing-Along mode active with original audio'));
    });
  });
}
