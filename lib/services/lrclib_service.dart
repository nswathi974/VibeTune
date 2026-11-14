import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/lyric_line_model.dart';
import 'lyrics_service.dart';

/// Result wrapper representing fetched lyrics from LRCLIB or local assets
class LrcResult {
  final bool isFound;
  final bool isSynced;
  final List<LyricLine> lyrics;
  final String? plainLyrics;
  final bool isInstrumental;
  final String sourceDescription;
  final String? errorMessage;

  const LrcResult({
    required this.isFound,
    required this.isSynced,
    required this.lyrics,
    this.plainLyrics,
    this.isInstrumental = false,
    required this.sourceDescription,
    this.errorMessage,
  });

  factory LrcResult.notFound([String? message]) => LrcResult(
        isFound: false,
        isSynced: false,
        lyrics: const [],
        sourceDescription: 'No lyrics available',
        errorMessage: message ?? 'Lyrics not found for this track',
      );

  factory LrcResult.fromAsset(List<LyricLine> lines, {String language = 'Original'}) => LrcResult(
        isFound: true,
        isSynced: true,
        lyrics: lines,
        plainLyrics: lines.map((l) => l.text).join('\n'),
        sourceDescription: 'Verified VibeTune ($language)',
      );

  Map<String, dynamic> toJson() => {
        'isFound': isFound,
        'isSynced': isSynced,
        'lyrics': lyrics
            .map((l) => {
                  'ms': l.timestamp.inMilliseconds,
                  'text': l.text,
                })
            .toList(),
        'plainLyrics': plainLyrics,
        'isInstrumental': isInstrumental,
        'sourceDescription': sourceDescription,
        'errorMessage': errorMessage,
      };

  factory LrcResult.fromJson(Map<String, dynamic> json) => LrcResult(
        isFound: json['isFound'] as bool? ?? false,
        isSynced: json['isSynced'] as bool? ?? false,
        lyrics: (json['lyrics'] as List<dynamic>? ?? [])
            .map((item) => LyricLine(
                  timestamp: Duration(milliseconds: item['ms'] as int? ?? 0),
                  text: item['text'] as String? ?? '',
                ))
            .toList(),
        plainLyrics: json['plainLyrics'] as String?,
        isInstrumental: json['isInstrumental'] as bool? ?? false,
        sourceDescription: json['sourceDescription'] as String? ?? '',
        errorMessage: json['errorMessage'] as String?,
      );
}

/// Service implementing LRCLIB API (https://lrclib.net/docs)
/// Fetches genuine synchronized and plain lyrics with disk caching,
/// smart artist/title sanitization, and graceful honest handling.
class LrclibService {
  static const String _baseUrl = 'https://lrclib.net/api';
  static const String _prefsPrefix = 'vibetune_lrclib_cache_';
  static final Map<String, LrcResult> _memoryCache = {};

  /// Sanitizes title by removing soundtrack noise, remixes, parentheticals, and bracket tags
  static String cleanTitle(String rawTitle) {
    var t = rawTitle.trim();
    // Remove (From "...") or (From movie ...)
    t = t.replaceAll(RegExp(r'\s*\((?:From|Original|Remix|Remastered|Feat|Ft|Audio)[^)]*\)', caseSensitive: false), '');
    // Remove brackets like [Remastered], [Official Audio]
    t = t.replaceAll(RegExp(r'\s*\[[^\]]*\]'), '');
    // Remove trailing " - From ..."
    t = t.replaceAll(RegExp(r'\s*-\s*From\s+.*$', caseSensitive: false), '');
    // Remove Pan-Indian/Hindi fusion parentheticals
    t = t.replaceAll(RegExp(r'\s*\([^)]*Anthem\)', caseSensitive: false), '');
    t = t.replaceAll(RegExp(r'\s*\([^)]*Fusion\)', caseSensitive: false), '');
    return t.trim();
  }

  /// Extracts primary artist name (first artist before comma, &, feat, /)
  static String extractPrimaryArtist(String rawArtist) {
    if (rawArtist.trim().isEmpty) return '';
    final parts = rawArtist.split(RegExp(r'[,&/;]|\bfeat\.?\b|\bft\.?\b', caseSensitive: false));
    return parts.first.trim();
  }

  /// Generates a normalized cache key for track and artist
  static String _cacheKey(String title, String artist) {
    final cleanT = cleanTitle(title).toLowerCase();
    final primaryA = extractPrimaryArtist(artist).toLowerCase();
    return '$cleanT::$primaryA';
  }

  static Future<LrcResult?> _readDiskCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('$_prefsPrefix$key');
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final data = jsonDecode(jsonStr) as Map<String, dynamic>;
        return LrcResult.fromJson(data);
      }
    } catch (e) {
      debugPrint('Error reading lyrics disk cache for $key: $e');
    }
    return null;
  }

  static Future<void> _writeDiskCache(String key, LrcResult result) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_prefsPrefix$key', jsonEncode(result.toJson()));
    } catch (e) {
      debugPrint('Error writing lyrics disk cache for $key: $e');
    }
  }

  /// Fetches lyrics for a song from LRCLIB.
  /// 1. In-memory cache check
  /// 2. Disk cache check
  /// 3. Exact GET /api/get with cleaned title & primary artist
  /// 4. Fallback GET /api/get with raw title & artist
  /// 5. Smart search /api/search with best-match scoring
  static Future<LrcResult> fetchLyrics({
    required String title,
    required String artist,
    String? album,
    int? durationSeconds,
  }) async {
    final key = _cacheKey(title, artist);

    // 1. In-memory cache
    if (_memoryCache.containsKey(key)) {
      return _memoryCache[key]!;
    }

    // 2. Persistent disk cache
    final cachedDisk = await _readDiskCache(key);
    if (cachedDisk != null && cachedDisk.isFound) {
      _memoryCache[key] = cachedDisk;
      return cachedDisk;
    }

    final cleanedTitle = cleanTitle(title);
    final primaryArtist = extractPrimaryArtist(artist);

    try {
      // 3. Attempt exact GET /api/get with cleaned title & primary artist
      final queryParams = <String, String>{
        'track_name': cleanedTitle,
        'artist_name': primaryArtist.isNotEmpty ? primaryArtist : artist.trim(),
      };
      if (album != null && album.isNotEmpty) queryParams['album_name'] = album.trim();
      if (durationSeconds != null && durationSeconds > 0) {
        queryParams['duration'] = durationSeconds.toString();
      }

      final getUri = Uri.parse('$_baseUrl/get').replace(queryParameters: queryParams);
      final response = await http
          .get(getUri, headers: {'User-Agent': 'VibeTune-MCA-Player/1.0'})
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final result = _parseLrclibResponse(data);
        if (result.isFound) {
          _memoryCache[key] = result;
          await _writeDiskCache(key, result);
          return result;
        }
      }

      // 4. If title was cleaned and differed, also try original raw title on /api/get
      if (cleanedTitle != title.trim()) {
        final rawParams = <String, String>{
          'track_name': title.trim(),
          'artist_name': artist.trim(),
        };
        final rawUri = Uri.parse('$_baseUrl/get').replace(queryParameters: rawParams);
        final rawResponse = await http
            .get(rawUri, headers: {'User-Agent': 'VibeTune-MCA-Player/1.0'})
            .timeout(const Duration(seconds: 4));

        if (rawResponse.statusCode == 200) {
          final data = jsonDecode(rawResponse.body) as Map<String, dynamic>;
          final result = _parseLrclibResponse(data);
          if (result.isFound) {
            _memoryCache[key] = result;
            await _writeDiskCache(key, result);
            return result;
          }
        }
      }

      // 5. Fallback to /api/search with track_name & artist_name or query `q`
      final searchQ = '$cleanedTitle $primaryArtist'.trim();
      final searchUri = Uri.parse('$_baseUrl/search').replace(queryParameters: {'q': searchQ});

      final searchResponse = await http
          .get(searchUri, headers: {'User-Agent': 'VibeTune-MCA-Player/1.0'})
          .timeout(const Duration(seconds: 4));

      if (searchResponse.statusCode == 200) {
        final list = jsonDecode(searchResponse.body) as List<dynamic>;
        if (list.isNotEmpty) {
          final bestMatch = _findBestMatch(
            list,
            cleanedTitle,
            primaryArtist,
            album: album,
            durationSeconds: durationSeconds,
          );
          if (bestMatch != null) {
            final result = _parseLrclibResponse(bestMatch);
            _memoryCache[key] = result;
            await _writeDiskCache(key, result);
            return result;
          }
        }
      }
    } catch (e) {
      debugPrint('LRCLIB fetch error for "$title - $artist": $e');
    }

    final notFound = LrcResult.notFound('Lyrics not available on LRCLIB for "$title"');
    _memoryCache[key] = notFound;
    return notFound;
  }

  /// Finds the best matching track from search results, strictly avoiding mismatched tracks,
  /// wrong versions (remixes, shortened edits vs full tracks), or mismatched durations.
  static Map<String, dynamic>? _findBestMatch(
    List<dynamic> results,
    String cleanedTitle,
    String primaryArtist, {
    String? album,
    int? durationSeconds,
  }) {
    final lowerTitle = cleanedTitle.toLowerCase().trim();
    final lowerArtist = primaryArtist.toLowerCase().trim();
    final lowerAlbum = (album != null && album.trim().isNotEmpty) ? album.toLowerCase().trim() : null;

    Map<String, dynamic>? bestMatch;
    int highestScore = -1;

    for (final item in results) {
      if (item is! Map<String, dynamic>) continue;
      final rawTrack = (item['trackName'] as String? ?? '').toLowerCase().trim();
      final trackName = cleanTitle(rawTrack).toLowerCase();
      final artistName = (item['artistName'] as String? ?? '').toLowerCase();
      final albumName = (item['albumName'] as String? ?? '').toLowerCase();
      final hasSynced = item['syncedLyrics'] != null && (item['syncedLyrics'] as String).trim().isNotEmpty;
      final hasPlain = item['plainLyrics'] != null && (item['plainLyrics'] as String).trim().isNotEmpty;
      final isInstrumental = item['instrumental'] as bool? ?? false;

      // Must have track match with clean title
      final bool trackMatches = trackName == lowerTitle ||
          trackName.contains(lowerTitle) ||
          lowerTitle.contains(trackName);

      if (!trackMatches) continue;

      int score = 0;
      if (trackName == lowerTitle) {
        score += 50;
      } else {
        score += 25;
      }

      if (lowerArtist.isNotEmpty && (artistName.contains(lowerArtist) || lowerArtist.contains(artistName))) {
        score += 35;
      }

      // Album alignment scoring
      if (lowerAlbum != null && albumName.isNotEmpty) {
        if (albumName == lowerAlbum) {
          score += 20;
        } else if (albumName.contains(lowerAlbum) || lowerAlbum.contains(albumName)) {
          score += 10;
        }
      }

      // Duration tolerance scoring (discourages mismatched edits, radio cuts, and extended versions)
      if (durationSeconds != null && durationSeconds > 0 && item['duration'] != null) {
        final itemDuration = (item['duration'] as num).toDouble();
        final diff = (itemDuration - durationSeconds).abs();
        if (diff <= 5) {
          score += 30; // Highly congruent duration match (within 5 seconds)
        } else if (diff <= 15) {
          score += 10;
        } else if (diff > 45) {
          score -= 35; // Substantial penalty for mismatched edit or wrong version
        }
      }

      if (hasSynced) {
        score += 40;
      } else if (hasPlain || isInstrumental) {
        score += 15;
      }

      if (score > highestScore) {
        highestScore = score;
        bestMatch = item;
      }
    }

    return highestScore >= 35 ? bestMatch : null;
  }

  /// Parses an LRCLIB item into an LrcResult honestly:
  /// - True synchronized lyrics if syncedLyrics exists
  /// - Genuine plain lyrics (without artificial timestamps) if plainLyrics exists
  /// - Instrumental flag if marked instrumental
  static LrcResult _parseLrclibResponse(Map<String, dynamic> data) {
    final isInstrumental = data['instrumental'] as bool? ?? false;
    final syncedLyricsStr = data['syncedLyrics'] as String?;
    final plainLyricsStr = data['plainLyrics'] as String?;

    if (isInstrumental) {
      return const LrcResult(
        isFound: true,
        isSynced: false,
        isInstrumental: true,
        lyrics: [],
        plainLyrics: '♪ Instrumental Composition — No Vocal Lyrics ♪',
        sourceDescription: 'LRCLIB (Instrumental Track)',
      );
    }

    if (syncedLyricsStr != null && syncedLyricsStr.trim().isNotEmpty) {
      final parsed = LyricsService.parseLrc(syncedLyricsStr);
      if (parsed.isNotEmpty) {
        return LrcResult(
          isFound: true,
          isSynced: true,
          lyrics: parsed,
          plainLyrics: plainLyricsStr ?? parsed.map((l) => l.text).join('\n'),
          sourceDescription: 'LRCLIB (Synchronized LRC)',
        );
      }
    }

    if (plainLyricsStr != null && plainLyricsStr.trim().isNotEmpty) {
      // Genuine plain lyrics without fabricated timestamps or pseudo-timers!
      return LrcResult(
        isFound: true,
        isSynced: false,
        lyrics: const [],
        plainLyrics: plainLyricsStr.trim(),
        sourceDescription: 'LRCLIB (Plain Lyrics — Unsynchronized)',
      );
    }

    return LrcResult.notFound();
  }

  /// Clears in-memory LRCLIB cache
  static void clearCache() {
    _memoryCache.clear();
  }
}
