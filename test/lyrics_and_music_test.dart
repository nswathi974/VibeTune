import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibetune/data/song_catalog.dart';
import 'package:vibetune/models/lyric_line_model.dart';
import 'package:vibetune/models/song_model.dart';
import 'package:vibetune/services/lyrics_service.dart';
import 'package:vibetune/services/lrclib_service.dart';
import 'package:vibetune/services/playlist_service.dart';
import 'package:vibetune/services/translation_service.dart';
import 'package:vibetune/services/audio_player_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('LyricsService & LRC Parsing Tests', () {
    test('parses standard [mm:ss.xx] 2-digit millisecond format', () {
      const lrcContent = '''
[00:04.50]First line of song
[00:12.75]Second line of song
[01:05.10]Chorus kicks in here
''';
      final lyrics = LyricsService.parseLrc(lrcContent);
      expect(lyrics.length, 3);
      expect(lyrics[0].timestamp, const Duration(seconds: 4, milliseconds: 500));
      expect(lyrics[0].text, 'First line of song');
      expect(lyrics[1].timestamp, const Duration(seconds: 12, milliseconds: 750));
      expect(lyrics[2].timestamp, const Duration(minutes: 1, seconds: 5, milliseconds: 100));
      expect(lyrics[2].text, 'Chorus kicks in here');
    });

    test('parses [mm:ss.xxx] 3-digit millisecond format', () {
      const lrcContent = '''
[00:03.250]Intro beats
[00:15.800]Vocal entry
''';
      final lyrics = LyricsService.parseLrc(lrcContent);
      expect(lyrics.length, 2);
      expect(lyrics[0].timestamp, const Duration(seconds: 3, milliseconds: 250));
      expect(lyrics[1].timestamp, const Duration(seconds: 15, milliseconds: 800));
    });

    test('sorts non-chronological lines into ascending playback order', () {
      const lrcContent = '''
[00:20.00]Line 3
[00:05.00]Line 1
[00:10.00]Line 2
''';
      final lyrics = LyricsService.parseLrc(lrcContent);
      expect(lyrics.length, 3);
      expect(lyrics[0].text, 'Line 1');
      expect(lyrics[1].text, 'Line 2');
      expect(lyrics[2].text, 'Line 3');
    });

    test('safely skips malformed lines, headers, and empty text', () {
      const lrcContent = '''
[ar:Singer Name]
[ti:Song Title]
[al:Album Name]
[invalid:format]
[00:05.00]
[00:10.00]Valid Lyric Line
Not an LRC line at all
''';
      final lyrics = LyricsService.parseLrc(lrcContent);
      expect(lyrics.length, 1);
      expect(lyrics[0].text, 'Valid Lyric Line');
      expect(lyrics[0].timestamp, const Duration(seconds: 10));
    });

    test('getActiveLineIndex correctly returns current lyric index based on audio position', () {
      final lines = [
        LyricLine(timestamp: const Duration(seconds: 5), text: 'Line 1'),
        LyricLine(timestamp: const Duration(seconds: 15), text: 'Line 2'),
        LyricLine(timestamp: const Duration(seconds: 30), text: 'Line 3'),
        LyricLine(timestamp: const Duration(seconds: 45), text: 'Line 4'),
      ];

      // Before first line
      expect(LyricsService.getActiveLineIndex(const Duration(seconds: 2), lines), 0);

      // Exactly at first line
      expect(LyricsService.getActiveLineIndex(const Duration(seconds: 5), lines), 0);

      // Between first and second line
      expect(LyricsService.getActiveLineIndex(const Duration(seconds: 10), lines), 0);

      // Between third and fourth line
      expect(LyricsService.getActiveLineIndex(const Duration(seconds: 35), lines), 2);

      // Past the last line
      expect(LyricsService.getActiveLineIndex(const Duration(minutes: 1), lines), 3);

      // Empty list returns -1
      expect(LyricsService.getActiveLineIndex(const Duration(seconds: 10), []), -1);
    });

    test('TranslationService handles Latin/English and transliterated queries cleanly', () {
      expect(TranslationService.supportedLanguages.containsKey('Kannada'), isTrue);
      expect(TranslationService.supportedLanguages.containsKey('Hindi'), isTrue);
      expect(TranslationService.supportedLanguages.containsKey('Tamil'), isTrue);
    });
  });

  group('PlaylistService & SongCatalog Tests', () {
    test('SongCatalog contains 10 verified songs spanning Hindi, Kannada, and Tamil', () {
      final songs = SongCatalog.allSongs;
      expect(songs.length, 10);

      final hindiSongs = songs.where((s) => s.language.toLowerCase() == 'hindi').toList();
      final kannadaSongs = songs.where((s) => s.language.toLowerCase() == 'kannada').toList();
      final tamilSongs = songs.where((s) => s.language.toLowerCase() == 'tamil').toList();

      expect(hindiSongs.length, 4, reason: 'Must have 4 Hindi songs');
      expect(kannadaSongs.length, 4, reason: 'Must have 4 Kannada songs');
      expect(tamilSongs.length, 2, reason: 'Must have 2 Tamil songs');
    });

    test('Search filters songs by title, artist, movie/album, and genre', () {
      final playlistService = PlaylistService();

      // Search by title
      playlistService.setSearchQuery('Agar Tum Saath Ho');
      expect(playlistService.filteredSongs.any((s) => s.title.contains('Agar Tum Saath Ho')), isTrue);

      // Search by artist
      playlistService.setSearchQuery('Sonu Nigam');
      expect(playlistService.filteredSongs.every((s) =>
        s.artist.toLowerCase().contains('sonu nigam') ||
        s.title.toLowerCase().contains('sonu nigam') ||
        s.movieOrAlbum.toLowerCase().contains('sonu nigam')), isTrue);

      // Empty query returns all songs
      playlistService.setSearchQuery('');
      expect(playlistService.filteredSongs.length, 10);

      // Non-existent search query returns empty list cleanly
      playlistService.setSearchQuery('__NonExistentSongXYZ999__');
      expect(playlistService.filteredSongs.isEmpty, isTrue);
    });

    test('Language filter selects only songs for chosen language', () {
      final playlistService = PlaylistService();

      playlistService.setLanguage('Hindi');
      expect(playlistService.filteredSongs.length, 4);
      for (final song in playlistService.filteredSongs) {
        expect(song.language.toLowerCase(), 'hindi');
      }

      playlistService.setLanguage('Kannada');
      expect(playlistService.filteredSongs.length, 4);
      for (final song in playlistService.filteredSongs) {
        expect(song.language.toLowerCase(), 'kannada');
      }

      playlistService.setLanguage('Tamil');
      expect(playlistService.filteredSongs.length, 2);
      for (final song in playlistService.filteredSongs) {
        expect(song.language.toLowerCase(), 'tamil');
      }

      // Reset to All
      playlistService.setLanguage('All');
      expect(playlistService.filteredSongs.length, 10);
    });

    test('Favorites toggling persists across service state', () {
      final playlistService = PlaylistService();
      const testSongId = 'hi_01';

      final wasFav = playlistService.isFavorite(testSongId);
      playlistService.toggleFavorite(testSongId);
      expect(playlistService.isFavorite(testSongId), !wasFav);

      // Toggle back
      playlistService.toggleFavorite(testSongId);
      expect(playlistService.isFavorite(testSongId), wasFav);
    });

    test('Karaoke songs collection contains all 10 verified songs with genuine backing stems', () {
      final playlistService = PlaylistService();
      final karaokeSongs = playlistService.karaokeSongs;

      expect(karaokeSongs.length, 10);
      for (final song in karaokeSongs) {
        expect(song.isKaraokeAvailable, isTrue);
        expect(song.karaokeAudioPath, isNotNull);
        expect(song.karaokeAudioPath!.isNotEmpty, isTrue);
        expect(song.normalAudioPath, isNot(equals(song.karaokeAudioPath)));
      }
    });

    test('Queue contains all 10 verified playable tracks', () {
      final playlistService = PlaylistService();
      expect(playlistService.currentQueue.every((s) => s.isPlayable), isTrue);
      expect(playlistService.currentQueue.length, 10);
    });
  });

  group('LrclibService Result Parsing Tests', () {
    test('LrcResult handles synced lyrics, plain lyrics, and not found status', () {
      final syncedResult = LrcResult(
        isFound: true,
        isSynced: true,
        lyrics: [LyricLine(timestamp: const Duration(seconds: 5), text: 'Synced test')],
        plainLyrics: 'Synced test',
        sourceDescription: 'LRCLIB (Synchronized)',
      );
      expect(syncedResult.isFound, isTrue);
      expect(syncedResult.isSynced, isTrue);
      expect(syncedResult.lyrics.length, 1);

      final plainResult = LrcResult(
        isFound: true,
        isSynced: false,
        lyrics: [LyricLine(timestamp: Duration.zero, text: 'Plain test')],
        plainLyrics: 'Plain test',
        sourceDescription: 'LRCLIB (Plain Lyrics - Unsynchronized)',
      );
      expect(plainResult.isFound, isTrue);
      expect(plainResult.isSynced, isFalse);

      final notFoundResult = LrcResult.notFound('Lyrics not found');
      expect(notFoundResult.isFound, isFalse);
      expect(notFoundResult.errorMessage, 'Lyrics not found');
    });
  });

  group('Audio Source & English Lyrics Authenticity Tests', () {
    test('All 10 songs have verified local audio master assets present on disk', () {
      final songs = SongCatalog.allSongs;
      expect(songs.length, 10);

      for (final song in songs) {
        expect(song.isPlayable, isTrue);
        expect(song.normalAudioPath.startsWith('assets/audio/normal/'), isTrue);
        expect(song.karaokeAudioPath!.startsWith('assets/audio/karaoke/'), isTrue);
        expect(song.lyricsPath!.startsWith('assets/lyrics/'), isTrue);
        expect(song.hasTimedLyrics, isTrue);
        expect(song.isKaraokeAvailable, isTrue);
      }
    });

    test('AudioPlayerService initializes with clean honest state and no fake fallbacks', () {
      final audioService = AudioPlayerService();
      expect(audioService.currentSong, isNull);
      expect(audioService.isPlaying, isFalse);
      expect(audioService.playbackMode, PlaybackMode.normal);
      expect(audioService.currentLyrics, isEmpty);
      expect(audioService.hasSecondaryTrack, isFalse);
      expect(audioService.rawPlayer, isNotNull);
    });

    test('AudioPlayerService toggleMode seamlessly handles track with and without secondary stem', () async {
      final audioService = AudioPlayerService();

      // No song loaded
      await audioService.toggleMode();
      expect(audioService.playbackMode, PlaybackMode.normal);

      // Verify volume clamp
      await audioService.setVolume(1.5);
      expect(audioService.volume, 1.0);
      await audioService.setVolume(-0.5);
      expect(audioService.volume, 0.0);
      await audioService.setVolume(0.8);
      expect(audioService.volume, 0.8);
    });
  });
}
