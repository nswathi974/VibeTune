import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/lyric_line_model.dart';

/// Multilingual Translation Service for VibeTune
/// Translates lyrics line-by-line while preserving timestamps and caching results.
class TranslationService {
  static final Map<String, String> _cache = {};

  static const Map<String, String> supportedLanguages = {
    'Original': 'orig',
    'English': 'en',
    'Hindi': 'hi',
    'Kannada': 'kn',
    'Telugu': 'te',
    'Tamil': 'ta',
    'Malayalam': 'ml',
  };

  /// Translates a single text string using MyMemory Translation API
  static Future<String> translateText({
    required String text,
    required String sourceLang,
    required String targetLang,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || sourceLang == targetLang) return text;

    // Check musical symbols or non-lyric cues (skip translation for audio cues like ♪)
    if (trimmed.startsWith('♪') && trimmed.endsWith('♪')) return text;

    final cacheKey = '$sourceLang::$targetLang::$trimmed';
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    try {
      final uri = Uri.parse('https://api.mymemory.translated.net/get').replace(
        queryParameters: {
          'q': trimmed,
          'langpair': '$sourceLang|$targetLang',
        },
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final responseData = data['responseData'] as Map<String, dynamic>?;
        final translated = responseData?['translatedText'] as String?;
        if (translated != null && translated.isNotEmpty && !translated.startsWith('MYMEMORY WARNING')) {
          _cache[cacheKey] = translated;
          return translated;
        }
      }
    } catch (e) {
      debugPrint('Translation error for "$trimmed": $e');
    }

    return text; // Return original on translation failure
  }

  /// Translates a list of synchronized LyricLines, preserving original timestamps!
  static Future<List<LyricLine>> translateLyrics({
    required List<LyricLine> lines,
    required String sourceLanguage,
    required String targetLanguage,
    void Function(double progress)? onProgress,
  }) async {
    final srcCode = supportedLanguages[sourceLanguage] ?? 'en';
    final tgtCode = supportedLanguages[targetLanguage] ?? 'en';

    if (srcCode == tgtCode || lines.isEmpty) {
      return lines;
    }

    final List<LyricLine> translatedLines = [];
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final translatedText = await translateText(
        text: line.text,
        sourceLang: srcCode,
        targetLang: tgtCode,
      );

      // Preserve exact timestamp
      translatedLines.add(LyricLine(
        timestamp: line.timestamp,
        text: translatedText,
      ));

      onProgress?.call((i + 1) / lines.length);
    }

    return translatedLines;
  }

  /// Clears in-memory translation cache
  static void clearCache() {
    _cache.clear();
  }
}
