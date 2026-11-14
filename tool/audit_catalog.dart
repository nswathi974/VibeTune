import 'package:vibetune/data/song_catalog.dart';

void main() {
  print('Total songs: ${SongCatalog.allSongs.length}');
  for (var s in SongCatalog.allSongs) {
    print('${s.id} | ${s.title} | ${s.artist} | ${s.movieOrAlbum} | ${s.language} | Playable: ${s.isPlayable} | Karaoke: ${s.isKaraokeAvailable} | TimedLyrics: ${s.hasTimedLyrics} | Lyrics: ${s.lyricsPath} | Audio: ${s.normalAudioPath} | KaraokeAudio: ${s.karaokeAudioPath}');
  }
}

