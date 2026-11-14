enum PlaybackMode {
  normal,
  karaoke,
}

class Song {
  final String id;
  final String title;
  final String artist;
  final String movieOrAlbum;
  final String language;
  final String coverImage;
  final String normalAudioPath;
  final String? karaokeAudioPath;
  final String? lyricsPath;
  final Duration duration;
  final int year;
  final String genre;
  final bool isKaraokeAvailable;
  final bool hasTimedLyrics;
  final bool isPlayable;
  final String? audioSourceNotice;
  final String? youtubeVideoId;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.movieOrAlbum,
    required this.language,
    required this.coverImage,
    required this.normalAudioPath,
    this.karaokeAudioPath,
    this.lyricsPath,
    required this.duration,
    required this.year,
    required this.genre,
    this.isKaraokeAvailable = true,
    this.hasTimedLyrics = true,
    this.isPlayable = true,
    this.audioSourceNotice,
    this.youtubeVideoId,
  });

  bool get isYouTubeTrack => youtubeVideoId != null && youtubeVideoId!.isNotEmpty;

  Song copyWith({
    String? id,
    String? title,
    String? artist,
    String? movieOrAlbum,
    String? language,
    String? coverImage,
    String? normalAudioPath,
    String? karaokeAudioPath,
    String? lyricsPath,
    Duration? duration,
    int? year,
    String? genre,
    bool? isKaraokeAvailable,
    bool? hasTimedLyrics,
    bool? isPlayable,
    String? audioSourceNotice,
    String? youtubeVideoId,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      movieOrAlbum: movieOrAlbum ?? this.movieOrAlbum,
      language: language ?? this.language,
      coverImage: coverImage ?? this.coverImage,
      normalAudioPath: normalAudioPath ?? this.normalAudioPath,
      karaokeAudioPath: karaokeAudioPath ?? this.karaokeAudioPath,
      lyricsPath: lyricsPath ?? this.lyricsPath,
      duration: duration ?? this.duration,
      year: year ?? this.year,
      genre: genre ?? this.genre,
      isKaraokeAvailable: isKaraokeAvailable ?? this.isKaraokeAvailable,
      hasTimedLyrics: hasTimedLyrics ?? this.hasTimedLyrics,
      isPlayable: isPlayable ?? this.isPlayable,
      audioSourceNotice: audioSourceNotice ?? this.audioSourceNotice,
      youtubeVideoId: youtubeVideoId ?? this.youtubeVideoId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'movieOrAlbum': movieOrAlbum,
      'language': language,
      'coverImage': coverImage,
      'normalAudioPath': normalAudioPath,
      'karaokeAudioPath': karaokeAudioPath,
      'lyricsPath': lyricsPath,
      'durationMs': duration.inMilliseconds,
      'year': year,
      'genre': genre,
      'isKaraokeAvailable': isKaraokeAvailable,
      'hasTimedLyrics': hasTimedLyrics,
      'isPlayable': isPlayable,
      'audioSourceNotice': audioSourceNotice,
      'youtubeVideoId': youtubeVideoId,
    };
  }

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String,
      movieOrAlbum: json['movieOrAlbum'] as String,
      language: json['language'] as String,
      coverImage: json['coverImage'] as String,
      normalAudioPath: json['normalAudioPath'] as String,
      karaokeAudioPath: json['karaokeAudioPath'] as String?,
      lyricsPath: json['lyricsPath'] as String?,
      duration: Duration(milliseconds: json['durationMs'] as int? ?? 210000),
      year: json['year'] as int? ?? 2024,
      genre: json['genre'] as String? ?? 'Indian Pop',
      isKaraokeAvailable: json['isKaraokeAvailable'] as bool? ?? true,
      hasTimedLyrics: json['hasTimedLyrics'] as bool? ?? true,
      isPlayable: json['isPlayable'] as bool? ?? true,
      audioSourceNotice: json['audioSourceNotice'] as String?,
      youtubeVideoId: json['youtubeVideoId'] as String?,
    );
  }
}
