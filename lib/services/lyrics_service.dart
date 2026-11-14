import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/lyric_line_model.dart';

class LyricsService {
  /// Parses standard LRC string content into a list of [LyricLine]
  static List<LyricLine> parseLrc(String content) {
    final lines = content.split(RegExp(r'\r?\n'));
    final List<LyricLine> lyricLines = [];
    final timeTagRegex = RegExp(r'\[(\d{1,2}):(\d{2})(?:\.(\d{1,3}))?\]');

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      final matches = timeTagRegex.allMatches(trimmed).toList();
      if (matches.isNotEmpty) {
        final lyricText = trimmed.replaceAll(timeTagRegex, '').trim();
        if (lyricText.isNotEmpty) {
          for (final match in matches) {
            final minutes = int.parse(match.group(1)!);
            final seconds = int.parse(match.group(2)!);
            final millisPart = match.group(3);
            int milliseconds = 0;
            if (millisPart != null && millisPart.isNotEmpty) {
              if (millisPart.length == 1) {
                milliseconds = int.parse(millisPart) * 100;
              } else if (millisPart.length == 2) {
                milliseconds = int.parse(millisPart) * 10;
              } else {
                milliseconds = int.parse(millisPart.substring(0, 3));
              }
            }

            final timestamp = Duration(
              minutes: minutes,
              seconds: seconds,
              milliseconds: milliseconds,
            );

            lyricLines.add(LyricLine(timestamp: timestamp, text: lyricText));
          }
        }
      }
    }

    // Sort chronologically
    lyricLines.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return lyricLines;
  }

  /// Loads an LRC asset file safely, falling back to an empty list or default on error
  static Future<List<LyricLine>> loadLyricsFromAsset(String assetPath) async {
    try {
      final content = await rootBundle.loadString(assetPath);
      return parseLrc(content);
    } catch (e, st) {
      debugPrint('Error loading lyrics asset "$assetPath": $e\n$st');
      // If asset is not found or fails to load, return empty list honestly
      return const [];
    }
  }

  /// Determines the currently active lyric line index for a given playback position
  static int getActiveLineIndex(Duration currentPosition, List<LyricLine> lyrics) {
    if (lyrics.isEmpty) return -1;
    if (currentPosition < lyrics.first.timestamp) return 0;

    int activeIndex = 0;
    for (int i = 0; i < lyrics.length; i++) {
      if (currentPosition >= lyrics[i].timestamp) {
        activeIndex = i;
      } else {
        break;
      }
    }
    return activeIndex;
  }
}
