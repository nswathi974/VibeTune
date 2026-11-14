import 'dart:io';
import 'package:vibetune/data/song_catalog.dart';

void main() async {
  print('=== AUDITING ALL SONGS IN SONGCATALOG ===\n');
  int total = SongCatalog.allSongs.length;
  int playable = 0;
  int withAudio = 0;
  int withLyrics = 0;
  int withKaraoke = 0;

  for (var s in SongCatalog.allSongs) {
    if (s.isPlayable) playable++;
    if (s.normalAudioPath.isNotEmpty) withAudio++;
    if (s.lyricsPath != null && s.lyricsPath!.isNotEmpty) withLyrics++;
    if (s.isKaraokeAvailable) withKaraoke++;

    print('[${s.id}] "${s.title}" (${s.language})');
    print('  Artist: ${s.artist} | Album: ${s.movieOrAlbum}');
    print('  Playable: ${s.isPlayable} | KaraokeAvailable: ${s.isKaraokeAvailable} | TimedLyrics: ${s.hasTimedLyrics}');
    print('  NormalAudio: ${s.normalAudioPath.isEmpty ? "NONE (Commercial license required)" : s.normalAudioPath}');
    print('  KaraokeAudio: ${s.karaokeAudioPath ?? "NONE"}');
    print('  Lyrics: ${s.lyricsPath ?? "NONE"}');

    // Test audio accessibility
    if (s.normalAudioPath.isNotEmpty) {
      if (s.normalAudioPath.startsWith('http://') || s.normalAudioPath.startsWith('https://')) {
        try {
          final client = HttpClient();
          client.connectionTimeout = const Duration(seconds: 4);
          final req = await client.headUrl(Uri.parse(s.normalAudioPath));
          req.headers.set('User-Agent', 'VibeTune/1.0');
          final res = await req.close();
          print('  -> Remote URL Status: ${res.statusCode} ${res.reasonPhrase}');
          client.close();
        } catch (e) {
          print('  -> Remote URL Error: $e');
        }
      } else {
        final f = File(s.normalAudioPath);
        final exists = f.existsSync();
        print('  -> Local Asset File: ${exists ? "EXISTS (${f.lengthSync()} bytes)" : "NOT FOUND ON DISK"}');
      }
    }

    if (s.lyricsPath != null && s.lyricsPath!.isNotEmpty) {
      final f = File(s.lyricsPath!);
      final exists = f.existsSync();
      print('  -> Local Lyrics File: ${exists ? "EXISTS (${f.lengthSync()} bytes)" : "NOT FOUND ON DISK"}');
    }
    print('');
  }

  print('=== SUMMARY ===');
  print('Total Songs: $total');
  print('Songs marked Playable: $playable');
  print('Songs with Audio Path: $withAudio');
  print('Songs with Lyrics Path: $withLyrics');
  print('Songs with Karaoke Track: $withKaraoke');
}

