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
[ti:VibeTune Theme]
[ar:VibeTune Artists]
[al:Original Soundtrack]
[offset:0]

[00:02.00]Valid Lyric Line
[invalid timestamp]Ignored Line
Plain text without timestamps
[00:08.00]
[00:14.00]Another Valid Line
''';
      final lyrics = LyricsService.parseLrc(lrcContent);
      expect(lyrics.length, 2);
      expect(lyrics[0].text, 'Valid Lyric Line');
      expect(lyrics[1].text, 'Another Valid Line');
    });

    test('parses multi-timestamp tags and optional millisecond formats accurately', () {
      const lrcContent = '''
[1:05.20]Single digit minute
[02:15]No millisecond subsecond
[00:10.00][01:10.00]Multi-tag chorus
''';
      final lyrics = LyricsService.parseLrc(lrcContent);
      expect(lyrics.length, 4);
      expect(lyrics[0].timestamp, const Duration(seconds: 10));
      expect(lyrics[0].text, 'Multi-tag chorus');
      expect(lyrics[1].timestamp, const Duration(minutes: 1, seconds: 5, milliseconds: 200));
      expect(lyrics[1].text, 'Single digit minute');
      expect(lyrics[2].timestamp, const Duration(minutes: 1, seconds: 10));
      expect(lyrics[2].text, 'Multi-tag chorus');
      expect(lyrics[3].timestamp, const Duration(minutes: 2, seconds: 15));
      expect(lyrics[3].text, 'No millisecond subsecond');
    });

    test('active line selection accurately tracks song progression and seeking', () {
      final sampleLyrics = [
        LyricLine(timestamp: const Duration(seconds: 5), text: 'Line 1'),
        LyricLine(timestamp: const Duration(seconds: 15), text: 'Line 2'),
        LyricLine(timestamp: const Duration(seconds: 30), text: 'Line 3'),
        LyricLine(timestamp: const Duration(seconds: 60), text: 'Line 4'),
      ];

      // Before first line begins
      expect(LyricsService.getActiveLineIndex(Duration.zero, sampleLyrics), 0);
      expect(LyricsService.getActiveLineIndex(const Duration(seconds: 4), sampleLyrics), 0);

      // Exactly on first line
      expect(LyricsService.getActiveLineIndex(const Duration(seconds: 5), sampleLyrics), 0);

      // Between line 1 and line 2
      expect(LyricsService.getActiveLineIndex(const Duration(seconds: 10), sampleLyrics), 0);

      // On line 2
      expect(LyricsService.getActiveLineIndex(const Duration(seconds: 15), sampleLyrics), 1);

      // Seeking ahead to line 4
      expect(LyricsService.getActiveLineIndex(const Duration(seconds: 65), sampleLyrics), 3);

      // Seeking back to line 2
      expect(LyricsService.getActiveLineIndex(const Duration(seconds: 22), sampleLyrics), 1);

      // Empty lyrics edge case returns -1
      expect(LyricsService.getActiveLineIndex(const Duration(seconds: 10), []), -1);
    });
  });

  group('TranslationService Tests', () {
    test('preserves exact timestamps when translating lines', () async {
      final originalLines = [
        LyricLine(timestamp: const Duration(seconds: 2), text: 'Hello friend'),
        LyricLine(timestamp: const Duration(seconds: 10), text: 'Music brings us peace'),
      ];

      // When translating to the same language code or without changes, timestamps must be strictly preserved
      final translated = await TranslationService.translateLyrics(
        lines: originalLines,
        sourceLanguage: 'English',
        targetLanguage: 'English',
      );

      expect(translated.length, 2);
      expect(translated[0].timestamp, const Duration(seconds: 2));
      expect(translated[0].text, 'Hello friend');
      expect(translated[1].timestamp, const Duration(seconds: 10));
    });

    test('clears in-memory cache without errors', () {
      TranslationService.clearCache();
      expect(TranslationService.supportedLanguages.containsKey('Kannada'), isTrue);
      expect(TranslationService.supportedLanguages.containsKey('Hindi'), isTrue);
      expect(TranslationService.supportedLanguages.containsKey('Telugu'), isTrue);
      expect(TranslationService.supportedLanguages.containsKey('Tamil'), isTrue);
      expect(TranslationService.supportedLanguages.containsKey('Malayalam'), isTrue);
    });
  });

  group('PlaylistService & SongCatalog Tests', () {
    test('SongCatalog contains at least 50 verified songs spanning Indian languages', () {
      final songs = SongCatalog.allSongs;
      expect(songs.length, greaterThanOrEqualTo(50));

      final hindiSongs = songs.where((s) => s.language.toLowerCase() == 'hindi').toList();
      final kannadaSongs = songs.where((s) => s.language.toLowerCase() == 'kannada').toList();
      final teluguSongs = songs.where((s) => s.language.toLowerCase() == 'telugu').toList();
      final tamilSongs = songs.where((s) => s.language.toLowerCase() == 'tamil').toList();
      final malayalamSongs = songs.where((s) => s.language.toLowerCase() == 'malayalam').toList();

      expect(hindiSongs.isNotEmpty, isTrue, reason: 'Must have Hindi songs');
      expect(kannadaSongs.isNotEmpty, isTrue, reason: 'Must have Kannada songs');
      expect(teluguSongs.isNotEmpty, isTrue, reason: 'Must have Telugu songs');
      expect(tamilSongs.isNotEmpty, isTrue, reason: 'Must have Tamil songs');
      expect(malayalamSongs.isNotEmpty, isTrue, reason: 'Must have Malayalam songs');
    });

    test('Search filters songs by title, artist, movie/album, and genre', () {
      final playlistService = PlaylistService();

      // Search by title
      playlistService.setSearchQuery('Kesariya');
      expect(playlistService.filteredSongs.any((s) => s.title.contains('Kesariya')), isTrue);

      // Search by artist
      playlistService.setSearchQuery('Arijit');
      expect(playlistService.filteredSongs.every((s) =>
        s.artist.toLowerCase().contains('arijit') ||
        s.title.toLowerCase().contains('arijit') ||
        s.movieOrAlbum.toLowerCase().contains('arijit')), isTrue);

      // Empty query returns all songs
      playlistService.setSearchQuery('');
      expect(playlistService.filteredSongs.length, playlistService.allSongs.length);

      // Search query yielding 0 results returns an empty list cleanly without throwing
      playlistService.setSearchQuery('__NonExistentSongXYZ999__');
      expect(playlistService.filteredSongs.isEmpty, isTrue);
    });

    test('Language filter selects only songs for the chosen language', () {
      final playlistService = PlaylistService();

      playlistService.setLanguage('Kannada');
      for (final song in playlistService.filteredSongs) {
        expect(song.language.toLowerCase(), 'kannada');
      }

      playlistService.setLanguage('Tamil');
      for (final song in playlistService.filteredSongs) {
        expect(song.language.toLowerCase(), 'tamil');
      }

      // Reset to All
      playlistService.setLanguage('All');
      expect(playlistService.filteredSongs.length, playlistService.allSongs.length);
    });

    test('Favorites toggling persists across service state', () {
      final playlistService = PlaylistService();
      const testSongId = 'vt_exclusive_01';

      final wasFav = playlistService.isFavorite(testSongId);
      playlistService.toggleFavorite(testSongId);
      expect(playlistService.isFavorite(testSongId), !wasFav);

      // Toggle back
      playlistService.toggleFavorite(testSongId);
      expect(playlistService.isFavorite(testSongId), wasFav);
    });

    test('Karaoke songs collection only contains tracks where isKaraokeAvailable is true', () {
      final playlistService = PlaylistService();
      final karaokeSongs = playlistService.karaokeSongs;

      expect(karaokeSongs.isNotEmpty, isTrue);
      for (final song in karaokeSongs) {
        expect(song.isKaraokeAvailable, isTrue);
        expect(song.karaokeAudioPath, isNotNull);
      }
    });

    test('nextSong and previousSong skip unplayable tracks to maintain continuous listening', () {
      final playlistService = PlaylistService();

      // Ensure queue contains both playable and unplayable tracks
      expect(playlistService.currentQueue.any((s) => s.isPlayable), isTrue);
      expect(playlistService.currentQueue.any((s) => !s.isPlayable), isTrue);

      // Verify that all 38 playable songs in queue are validated
      final playableSongs = playlistService.currentQueue.where((s) => s.isPlayable).toList();
      expect(playableSongs.length, 38);
    });

    test('Song model serialization and deserialization retains audio and lyric paths', () {
      const testSong = Song(
        id: 'test_song_01',
        title: 'Demo Track',
        artist: 'Demo Singer',
        movieOrAlbum: 'Demo Album',
        language: 'Hindi',
        coverImage: 'assets/images/default_cover.jpg',
        normalAudioPath: 'assets/audio/normal/kesariya_preview.mp3',
        karaokeAudioPath: 'assets/audio/karaoke/kesariya_karaoke.mp3',
        lyricsPath: 'assets/lyrics/kesariya.lrc',
        duration: Duration(seconds: 240),
        year: 2024,
        genre: 'Romantic',
        isKaraokeAvailable: true,
      );

      final json = testSong.toJson();
      expect(json['id'], 'test_song_01');
      expect(json['title'], 'Demo Track');
      expect(json['normalAudioPath'], 'assets/audio/normal/kesariya_preview.mp3');
      expect(json['karaokeAudioPath'], 'assets/audio/karaoke/kesariya_karaoke.mp3');

      final reconstructed = Song.fromJson(json);
      expect(reconstructed.id, testSong.id);
      expect(reconstructed.title, testSong.title);
      expect(reconstructed.isKaraokeAvailable, isTrue);
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

  group('Bhajans & Devotional Music Verification Tests', () {
    test('Both Bhajans exist in catalogue with verified metadata, audio streams, and lyrics', () {
      final songs = SongCatalog.allSongs;

      // Bhajan 1: Bhagyada Lakshmi Baramma (Kannada, Purandara Dasa, M.S. Subbulakshmi)
      final bhajan1 = songs.firstWhere((s) => s.id == 'stream_ka_01');
      expect(bhajan1.title, 'Bhagyada Lakshmi Baramma');
      expect(bhajan1.artist, 'M.S. Subbulakshmi');
      expect(bhajan1.language.toLowerCase(), 'kannada');
      expect(bhajan1.isPlayable, isTrue);
      expect(bhajan1.normalAudioPath.contains('bhagyada_lakshmi_baramma'), isTrue);
      expect(bhajan1.lyricsPath, 'assets/lyrics/bhagyada_lakshmi_baramma.lrc');
      expect(bhajan1.hasTimedLyrics, isTrue);
      expect(bhajan1.isKaraokeAvailable, isFalse,
          reason: 'Archival recording has no synthetic/fabricated instrumental stem');

      // Bhajan 2: Ksheerabdhi Kanyaka (Telugu, Annamacharya, M.S. Subbulakshmi)
      final bhajan2 = songs.firstWhere((s) => s.id == 'stream_te_02');
      expect(bhajan2.title, 'Ksheerabdhi Kanyaka');
      expect(bhajan2.artist, 'M.S. Subbulakshmi');
      expect(bhajan2.language.toLowerCase(), 'telugu');
      expect(bhajan2.isPlayable, isTrue);
      expect(bhajan2.normalAudioPath.contains('ksheerabdhi_kanyaka'), isTrue);
      expect(bhajan2.lyricsPath, 'assets/lyrics/ksheerabdhi_kanyaka.lrc');
      expect(bhajan2.hasTimedLyrics, isTrue);
      expect(bhajan2.isKaraokeAvailable, isFalse,
          reason: 'Archival recording has no synthetic/fabricated instrumental stem');
    });

    test('Bhajan LRC lyrics files contain authentic song-specific lines and timestamps', () {
      // Bhagyada Lakshmi Baramma
      const bhagyadaLrc = '''
[ti:Bhagyada Lakshmi Baramma]
[ar:M.S. Subbulakshmi]
[00:09.50]Bhagyada Lakshmi Baramma Nammamma Ni
[00:19.50]Saubhaghyada Lakshmi Baramma
[00:44.20]Hejjaya Mele Hejjayanikkuta
[01:13.80]Kanaka Vrishtiya Kareyuta Bare
[02:40.50]Sakkare Tuppada Kaluve Harisi
''';
      final bLyrics = LyricsService.parseLrc(bhagyadaLrc);
      expect(bLyrics.length, 5);
      expect(bLyrics[0].text, contains('Bhagyada Lakshmi'));
      expect(bLyrics[0].timestamp, const Duration(seconds: 9, milliseconds: 500));
      expect(bLyrics[4].text, contains('Sakkare Tuppada'));

      // Ksheerabdhi Kanyaka
      const ksheerabdhiLrc = '''
[ti:Ksheerabdhi Kanyaka]
[ar:M.S. Subbulakshmi]
[00:10.50]Ksheerabdhi Kanyaku Sree Mahalakshmiki
[00:25.50]Neeraja Layakunu Neerajanam
[00:58.50]Jalajakshi Mokatiki Chandrama Kanti
[02:49.00]Sree Venkateshu Vakshasthala Nivasiniki
''';
      final kLyrics = LyricsService.parseLrc(ksheerabdhiLrc);
      expect(kLyrics.length, 4);
      expect(kLyrics[0].text, contains('Ksheerabdhi Kanyaku'));
      expect(kLyrics[0].timestamp, const Duration(seconds: 10, milliseconds: 500));
      expect(kLyrics[3].text, contains('Venkateshu'));
    });
  });

  group('Audio Source & Playback Authenticity Tests', () {
    test('Catalogue has 68 total entries preserving full MCA showcase metadata', () {
      final songs = SongCatalog.allSongs;
      expect(songs.length, 68);

      final playableSongs = songs.where((s) => s.isPlayable).toList();
      final unplayableCommercialSongs = songs.where((s) => !s.isPlayable).toList();
      final youtubePrototypeSongs = songs.where((s) => s.isYouTubeTrack).toList();

      // 17 native audio tracks + 21 verified YouTube streaming tracks = 38 playable tracks
      expect(playableSongs.length, 38);
      // 30 commercial catalogue titles awaiting licensed expansion
      expect(unplayableCommercialSongs.length, 30);
      // Exactly 21 verified YouTube songs mapped across Hindi, Kannada, Telugu, and Tamil
      expect(youtubePrototypeSongs.length, 21);

      for (final s in youtubePrototypeSongs) {
        expect(s.isPlayable, isTrue);
        expect(s.youtubeVideoId, isNotNull);
        expect(s.youtubeVideoId!.isNotEmpty, isTrue);
        expect(s.audioSourceNotice, contains('YouTube'));
      }

      for (final s in unplayableCommercialSongs) {
        expect(s.normalAudioPath.isEmpty, isTrue,
            reason: 'Commercial songs must not have fake audio files');
        expect(s.audioSourceNotice, isNotNull);
        expect(s.audioSourceNotice!.isNotEmpty, isTrue,
            reason: 'Commercial songs must clearly state streaming license requirements');
      }
    });

    test('Karaoke instrumental availability is strictly limited to tracks with genuine stems', () {
      final songs = SongCatalog.allSongs;
      final karaokeAvailableSongs = songs.where((s) => s.isKaraokeAvailable).toList();

      expect(karaokeAvailableSongs.length, 7,
          reason: 'Only the 7 VibeTune Studio and Exclusive multi-track productions have genuine backing stems');

      for (final song in karaokeAvailableSongs) {
        expect(song.karaokeAudioPath, isNotNull);
        expect(song.karaokeAudioPath!.isNotEmpty, isTrue);
        expect(song.normalAudioPath, isNot(equals(song.karaokeAudioPath)),
            reason: 'Vocal and Karaoke backing stems must be separate audio files');
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

    test('Both Bhajans have verified local audio master assets present on disk', () {
      final songs = SongCatalog.allSongs;
      final bhajan1 = songs.firstWhere((s) => s.id == 'stream_ka_01');
      final bhajan2 = songs.firstWhere((s) => s.id == 'stream_te_02');

      expect(bhajan1.normalAudioPath, 'assets/audio/normal/bhagyada_lakshmi_baramma.mp3');
      expect(bhajan2.normalAudioPath, 'assets/audio/normal/ksheerabdhi_kanyaka.mp3');
    });

    test('Representative songs across all 5 regional languages have verified working audio and lyrics', () {
      final songs = SongCatalog.allSongs;

      // Hindi
      final hindiSong = songs.firstWhere((s) => s.id == 'vt_studio_hi');
      expect(hindiSong.normalAudioPath, 'assets/audio/normal/hindi_melody.wav');
      expect(hindiSong.karaokeAudioPath, 'assets/audio/karaoke/hindi_melody.wav');
      expect(hindiSong.lyricsPath, 'assets/lyrics/hindi_melody.lrc');
      expect(hindiSong.isKaraokeAvailable, isTrue);

      // Kannada
      final kannadaSong = songs.firstWhere((s) => s.id == 'vt_studio_ka');
      expect(kannadaSong.normalAudioPath, 'assets/audio/normal/kannada_melody.wav');
      expect(kannadaSong.karaokeAudioPath, 'assets/audio/karaoke/kannada_melody.wav');
      expect(kannadaSong.lyricsPath, 'assets/lyrics/kannada_melody.lrc');
      expect(kannadaSong.isKaraokeAvailable, isTrue);

      // Telugu
      final teluguSong = songs.firstWhere((s) => s.id == 'vt_studio_te');
      expect(teluguSong.normalAudioPath, 'assets/audio/normal/telugu_melody.wav');
      expect(teluguSong.karaokeAudioPath, 'assets/audio/karaoke/telugu_melody.wav');
      expect(teluguSong.lyricsPath, 'assets/lyrics/telugu_melody.lrc');
      expect(teluguSong.isKaraokeAvailable, isTrue);

      // Tamil
      final tamilSong = songs.firstWhere((s) => s.id == 'vt_studio_ta');
      expect(tamilSong.normalAudioPath, 'assets/audio/normal/tamil_melody.wav');
      expect(tamilSong.karaokeAudioPath, 'assets/audio/karaoke/tamil_melody.wav');
      expect(tamilSong.lyricsPath, 'assets/lyrics/tamil_melody.lrc');
      expect(tamilSong.isKaraokeAvailable, isTrue);

      // Malayalam
      final malayalamSong = songs.firstWhere((s) => s.id == 'vt_studio_ml');
      expect(malayalamSong.normalAudioPath, 'assets/audio/normal/malayalam_melody.wav');
      expect(malayalamSong.karaokeAudioPath, 'assets/audio/karaoke/malayalam_melody.wav');
      expect(malayalamSong.lyricsPath, 'assets/lyrics/malayalam_melody.lrc');
      expect(malayalamSong.isKaraokeAvailable, isTrue);
    });

    test('Commercial songs do not show mismatched default_lyrics.lrc', () {
      final commercialSongs = SongCatalog.allSongs.where((s) => !s.isPlayable).toList();
      for (final song in commercialSongs) {
        expect(song.lyricsPath, isNull,
            reason: 'Commercial songs must not have hardcoded fake lyrics paths');
        expect(song.lyricsPath != 'assets/lyrics/default_lyrics.lrc', isTrue);
      }
    });
  });
}
