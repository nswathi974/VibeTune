import '../lib/data/song_catalog.dart';

void main() {
  final playable = SongCatalog.allSongs.where((s) => s.isPlayable).toList();
  print('TOTAL PLAYABLE SONGS: ${playable.length}');
  for (var i = 0; i < playable.length; i++) {
    final s = playable[i];
    final isLocal = s.normalAudioPath.startsWith('assets/');
    final type = s.isYouTubeTrack ? 'YOUTUBE' : (isLocal ? 'LOCAL_DUAL_STEM' : 'ARCHIVE_STREAM');
    print('${i + 1}. [$type] ID: ${s.id} | Title: "${s.title}" (${s.language}) | KaraokeStem: ${s.karaokeAudioPath != null} | LyricsPath: ${s.lyricsPath} | YT: ${s.youtubeVideoId}');
  }
}
