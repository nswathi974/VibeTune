import '../models/song_model.dart';

/// VibeTune Master Song Catalog
///
/// Contains 10 verified Indian songs across 3 regional languages:
/// - Hindi (4 songs)
/// - Kannada (4 songs)
/// - Tamil (2 songs)
///
/// All 10 songs feature BOTH genuine Normal (vocal) and Karaoke (instrumental)
/// audio tracks with synchronized LRC lyrics and distinct custom album art.
class SongCatalog {
  static final List<Song> _rawSongs = [
    // =============================================================
    // HINDI SONGS (4 TRACKS)
    // =============================================================
    const Song(
      id: 'hi_01',
      title: 'Agar Tum Saath Ho',
      artist: 'Alka Yagnik, Arijit Singh',
      movieOrAlbum: 'Tamasha',
      language: 'Hindi',
      coverImage: 'assets/images/covers/cover_agar_tum_saath_ho.jpg',
      normalAudioPath: 'assets/audio/normal/agar_tum_saath_ho.mp3',
      karaokeAudioPath: 'assets/audio/karaoke/agar_tum_saath_ho_karaoke.mp3',
      lyricsPath: 'assets/lyrics/agar_tum_saath_ho.lrc',
      duration: Duration(minutes: 5, seconds: 41),
      year: 2015,
      genre: 'Romantic Melody',
      isKaraokeAvailable: true,
      hasTimedLyrics: true,
      isPlayable: true,
      audioSourceNotice: 'Full dual-stem track: Original vocal & official instrumental karaoke stem.',
    ),
    const Song(
      id: 'hi_02',
      title: 'Chahun Main Ya Naa',
      artist: 'Arijit Singh, Palak Muchhal',
      movieOrAlbum: 'Aashiqui 2',
      language: 'Hindi',
      coverImage: 'assets/images/covers/cover_chahun_main_ya_naa.jpg',
      normalAudioPath: 'assets/audio/normal/chahun_main_ya_naa.mp3',
      karaokeAudioPath: 'assets/audio/karaoke/chahun_main_ya_naa_karaoke.mp3',
      lyricsPath: 'assets/lyrics/chahun_main_ya_naa.lrc',
      duration: Duration(minutes: 4, seconds: 0),
      year: 2013,
      genre: 'Romantic Ballad',
      isKaraokeAvailable: true,
      hasTimedLyrics: true,
      isPlayable: true,
      audioSourceNotice: 'Full dual-stem track: Original vocal & official instrumental karaoke stem.',
    ),
    const Song(
      id: 'hi_03',
      title: 'Kaun Tujhe',
      artist: 'Palak Muchhal',
      movieOrAlbum: 'M.S. Dhoni - The Untold Story',
      language: 'Hindi',
      coverImage: 'assets/images/covers/cover_kaun_tujhe.jpg',
      normalAudioPath: 'assets/audio/normal/kaun_tujhe.mp3',
      karaokeAudioPath: 'assets/audio/karaoke/kaun_tujhe_karaoke.mp3',
      lyricsPath: 'assets/lyrics/kaun_tujhe.lrc',
      duration: Duration(minutes: 4, seconds: 2),
      year: 2016,
      genre: 'Melodic Romance',
      isKaraokeAvailable: true,
      hasTimedLyrics: true,
      isPlayable: true,
      audioSourceNotice: 'Full dual-stem track: Original vocal & official instrumental karaoke stem.',
    ),
    const Song(
      id: 'hi_04',
      title: 'Kalyani (Kya Fitoor)',
      artist: 'Shreya Ghoshal, ARJN, KDS',
      movieOrAlbum: 'Indie Release',
      language: 'Hindi',
      coverImage: 'assets/images/covers/cover_kalyani.jpg',
      normalAudioPath: 'assets/audio/normal/kalyani.mp3',
      karaokeAudioPath: 'assets/audio/karaoke/kalyani_karaoke.mp3',
      lyricsPath: 'assets/lyrics/kalyani.lrc',
      duration: Duration(minutes: 4, seconds: 8),
      year: 2024,
      genre: 'Contemporary Pop',
      isKaraokeAvailable: true,
      hasTimedLyrics: true,
      isPlayable: true,
      audioSourceNotice: 'Full dual-stem track: Original vocal & official instrumental karaoke stem.',
    ),

    // =============================================================
    // KANNADA SONGS (4 TRACKS)
    // =============================================================
    const Song(
      id: 'ka_01',
      title: 'Anisuthide',
      artist: 'Sonu Nigam',
      movieOrAlbum: 'Mungaru Male',
      language: 'Kannada',
      coverImage: 'assets/images/covers/cover_anisuthide.jpg',
      normalAudioPath: 'assets/audio/normal/anisuthide.mp3',
      karaokeAudioPath: 'assets/audio/karaoke/anisuthide_karaoke.mp3',
      lyricsPath: 'assets/lyrics/anisuthide.lrc',
      duration: Duration(minutes: 4, seconds: 50),
      year: 2006,
      genre: 'Kannada Romantic Classic',
      isKaraokeAvailable: true,
      hasTimedLyrics: true,
      isPlayable: true,
      audioSourceNotice: 'Full dual-stem track: Original vocal & official instrumental karaoke stem.',
    ),
    const Song(
      id: 'ka_02',
      title: 'Ninnindale',
      artist: 'Sonu Nigam',
      movieOrAlbum: 'Milana',
      language: 'Kannada',
      coverImage: 'assets/images/covers/cover_ninnindale.jpg',
      normalAudioPath: 'assets/audio/normal/ninnindale.mp3',
      karaokeAudioPath: 'assets/audio/karaoke/ninnindale_karaoke.mp3',
      lyricsPath: 'assets/lyrics/ninnindale.lrc',
      duration: Duration(minutes: 4, seconds: 56),
      year: 2007,
      genre: 'Kannada Melodic Pop',
      isKaraokeAvailable: true,
      hasTimedLyrics: true,
      isPlayable: true,
      audioSourceNotice: 'Full dual-stem track: Original vocal & official instrumental karaoke stem.',
    ),
    const Song(
      id: 'ka_03',
      title: 'Nooru Janmaku',
      artist: 'Rajesh Krishnan',
      movieOrAlbum: 'America America',
      language: 'Kannada',
      coverImage: 'assets/images/covers/cover_nooru_janmaku.jpg',
      normalAudioPath: 'assets/audio/normal/nooru_janmaku.mp3',
      karaokeAudioPath: 'assets/audio/karaoke/nooru_janmaku_karaoke.mp3',
      lyricsPath: 'assets/lyrics/nooru_janmaku.lrc',
      duration: Duration(minutes: 4, seconds: 19),
      year: 1997,
      genre: 'Kannada Evergreen',
      isKaraokeAvailable: true,
      hasTimedLyrics: true,
      isPlayable: true,
      audioSourceNotice: 'Full dual-stem track: Original vocal & official instrumental karaoke stem.',
    ),
    const Song(
      id: 'ka_04',
      title: 'Yendu Kanda Kanasu',
      artist: 'Rajesh Krishnan, Kavitha Krishnamurthy',
      movieOrAlbum: 'Kalasipalya',
      language: 'Kannada',
      coverImage: 'assets/images/covers/cover_yendu_kanda_kanasu.jpg',
      normalAudioPath: 'assets/audio/normal/yendu_kanda_kanasu.mp3',
      karaokeAudioPath: 'assets/audio/karaoke/yendu_kanda_kanasu_karaoke.mp3',
      lyricsPath: 'assets/lyrics/yendu_kanda_kanasu.lrc',
      duration: Duration(minutes: 5, seconds: 55),
      year: 2004,
      genre: 'Kannada Romantic Duet',
      isKaraokeAvailable: true,
      hasTimedLyrics: true,
      isPlayable: true,
      audioSourceNotice: 'Full dual-stem track: Original vocal & official instrumental karaoke stem.',
    ),

    // =============================================================
    // TAMIL SONGS (2 TRACKS)
    // =============================================================
    const Song(
      id: 'ta_01',
      title: 'Thuli Thuli',
      artist: 'Haricharan, Tanvi Shah, Yuvan Shankar Raja',
      movieOrAlbum: 'Paiyaa',
      language: 'Tamil',
      coverImage: 'assets/images/covers/cover_thuli_thuli.jpg',
      normalAudioPath: 'assets/audio/normal/thuli_thuli.mp3',
      karaokeAudioPath: 'assets/audio/karaoke/thuli_thuli_karaoke.mp3',
      lyricsPath: 'assets/lyrics/thuli_thuli.lrc',
      duration: Duration(minutes: 4, seconds: 29),
      year: 2010,
      genre: 'Tamil Breeze Pop',
      isKaraokeAvailable: true,
      hasTimedLyrics: true,
      isPlayable: true,
      audioSourceNotice: 'Full dual-stem track: Original vocal & official instrumental karaoke stem.',
    ),
    const Song(
      id: 'ta_02',
      title: 'Pesamale',
      artist: 'Siri, Xander, Arra, Aria Khayal',
      movieOrAlbum: 'Sony Music Indie',
      language: 'Tamil',
      coverImage: 'assets/images/covers/cover_pesamale.jpg',
      normalAudioPath: 'assets/audio/normal/pesamale.mp3',
      karaokeAudioPath: 'assets/audio/karaoke/pesamale_karaoke.mp3',
      lyricsPath: 'assets/lyrics/pesamale.lrc',
      duration: Duration(minutes: 3, seconds: 27),
      year: 2023,
      genre: 'Tamil Indie Pop',
      isKaraokeAvailable: true,
      hasTimedLyrics: true,
      isPlayable: true,
      audioSourceNotice: 'Full dual-stem track: Original vocal & official instrumental karaoke stem.',
    ),
  ];

  static List<Song> get allSongs => List.unmodifiable(_rawSongs);

  static List<String> get availableLanguages => [
        'All',
        'Hindi',
        'Kannada',
        'Tamil',
      ];

  // Helper getters for language sections
  static List<Song> get hindiSongs =>
      _rawSongs.where((s) => s.language.toLowerCase() == 'hindi').toList();

  static List<Song> get kannadaSongs =>
      _rawSongs.where((s) => s.language.toLowerCase() == 'kannada').toList();

  static List<Song> get tamilSongs =>
      _rawSongs.where((s) => s.language.toLowerCase() == 'tamil').toList();
}
