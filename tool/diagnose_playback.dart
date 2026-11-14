import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('=== VIBETUNE PLAYBACK & API DIAGNOSTIC ===\n');

  // 1. Test LRCLIB API
  print('--- 1. Testing LRCLIB Lyrics & Metadata API ---');
  final lrclibUrls = [
    'https://lrclib.net/api/get?track_name=Kesariya&artist_name=Arijit+Singh',
    'https://lrclib.net/api/get?track_name=Neon+Raga&artist_name=Kavi+Raj',
  ];

  for (final url in lrclibUrls) {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 5);
      final request = await client.getUrl(Uri.parse(url));
      request.headers.set('User-Agent', 'VibeTuneApp/1.0');
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      print('URL: $url');
      print('Status: ${response.statusCode} ${response.reasonPhrase}');
      print('Content-Type: ${response.headers.value(HttpHeaders.contentTypeHeader)}');
      if (response.statusCode == 200) {
        final json = jsonDecode(body) as Map<String, dynamic>;
        print('Returned keys: ${json.keys.toList()}');
        print('Has audio URL?: ${json.containsKey("audio") || json.containsKey("url") || json.containsKey("audioUrl") || json.containsKey("downloadUrl")}');
        print('syncedLyrics length: ${(json["syncedLyrics"] as String?)?.length ?? 0}');
        print('plainLyrics length: ${(json["plainLyrics"] as String?)?.length ?? 0}');
        print('instrumental flag: ${json["instrumental"]}');
      } else {
        print('Response body: $body');
      }
      client.close();
    } catch (e) {
      print('URL: $url => Exception: $e');
    }
    print('');
  }

  // 2. Test Audio Stream URLs in SongCatalog
  print('--- 2. Testing SongCatalog Remote Audio URLs ---');
  final audioUrls = [
    'https://archive.org/download/emoe-506-b-1/Sitar%20Raga%20Kirwani.mp3',
    'https://archive.org/download/emoe-506-b-1/Sitar%20Raga%20Bhatiyar.mp3',
    'https://archive.org/download/LakshmiKataksham/Lakshmi%20Kataksham/10%20Bhagyada%20Lakshmi%20Baramma.mp3',
    'https://archive.org/download/MLV-Purandaradasa-Krithis/MLV%20Purandaradasa%20Krithis%20LRC/01%20Sharanu%20Siddhi%20Vinayaka%20-%20Sowrashtram%20-%20Purandaradasa.mp3',
    'https://archive.org/download/sanjay-subrahmanyan-carnatic-vocal/Sanjay%20Subrahmanyan/01-Sobillu.mp3',
    'https://archive.org/download/LakshmiKataksham/Lakshmi%20Kataksham/11%20Ksheerabdhi%20Kanyaka.mp3',
    'https://archive.org/download/LakshmiKataksham/Lakshmi%20Kataksham/09%20Kurai%20Onrum%20Illai.mp3',
    'https://archive.org/download/kvn-mc-tn-swathi-thirunal-1980s/01%20Gopa%20Nandana%20-%20Bhooshavali%20-%20Swathi%20Thirunal.mp3',
    'https://archive.org/download/kvn-mc-tn-swathi-thirunal-1980s/04%20Rajeevaksha%20Baro%20-%20Sankarabaranam%20-%20Swathi%20Thirunal.mp3',
    'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
  ];

  for (final url in audioUrls) {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 6);
      final request = await client.getUrl(Uri.parse(url));
      request.headers.set('User-Agent', 'VibeTuneApp/1.0 (Android; Mobile)');
      request.followRedirects = false; // Check initial response first
      final response = await request.close();
      print('URL: $url');
      print('HTTP Initial Status: ${response.statusCode} ${response.reasonPhrase}');
      print('Location (redirect): ${response.headers.value(HttpHeaders.locationHeader)}');
      print('Content-Type: ${response.headers.value(HttpHeaders.contentTypeHeader)}');
      print('Content-Length: ${response.headers.value(HttpHeaders.contentLengthHeader)}');
      client.close();

      // Now follow redirect if 301/302
      if (response.statusCode == 301 || response.statusCode == 302) {
        final redirectUrl = response.headers.value(HttpHeaders.locationHeader);
        if (redirectUrl != null) {
          final client2 = HttpClient();
          client2.connectionTimeout = const Duration(seconds: 6);
          try {
            final req2 = await client2.getUrl(Uri.parse(redirectUrl));
            req2.headers.set('User-Agent', 'VibeTuneApp/1.0 (Android; Mobile)');
            final res2 = await req2.close();
            print('  -> Redirected Status: ${res2.statusCode} ${res2.reasonPhrase}');
            print('  -> Redirected Content-Type: ${res2.headers.value(HttpHeaders.contentTypeHeader)}');
            print('  -> Redirected Content-Length: ${res2.headers.value(HttpHeaders.contentLengthHeader)}');
          } catch (e2) {
            print('  -> Redirected Request Failed: $e2');
          }
          client2.close();
        }
      }
    } catch (e) {
      print('URL: $url => Initial Request Failed: $e');
    }
    print('');
  }

  // 3. Check Local Asset WAV files
  print('--- 3. Checking Local Asset Files ---');
  final localAssets = [
    'assets/audio/normal/hindi_melody.wav',
    'assets/audio/karaoke/hindi_melody.wav',
    'assets/audio/normal/kannada_melody.wav',
    'assets/audio/karaoke/kannada_melody.wav',
    'assets/audio/normal/telugu_melody.wav',
    'assets/audio/karaoke/telugu_melody.wav',
    'assets/audio/normal/tamil_melody.wav',
    'assets/audio/karaoke/tamil_melody.wav',
    'assets/audio/normal/malayalam_melody.wav',
    'assets/audio/karaoke/malayalam_melody.wav',
    'assets/lyrics/hindi_melody.lrc',
    'assets/lyrics/kannada_melody.lrc',
    'assets/lyrics/telugu_melody.lrc',
    'assets/lyrics/tamil_melody.lrc',
    'assets/lyrics/malayalam_melody.lrc',
    'assets/lyrics/default_lyrics.lrc',
  ];

  for (final path in localAssets) {
    final file = File(path);
    if (file.existsSync()) {
      print('Asset "$path": EXISTS (${file.lengthSync()} bytes)');
    } else {
      print('Asset "$path": MISSING!');
    }
  }

  print('\n=== DIAGNOSTIC COMPLETE ===');
}
