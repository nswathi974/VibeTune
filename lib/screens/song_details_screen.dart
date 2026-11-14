import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song_model.dart';
import '../services/audio_player_service.dart';
import '../services/playlist_service.dart';
import '../services/lyrics_service.dart';
import '../services/lrclib_service.dart';
import '../models/lyric_line_model.dart';
import '../theme/app_colors.dart';
import 'player/full_player_screen.dart';
import 'player/karaoke_player_screen.dart';
import '../widgets/add_to_playlist_dialog.dart';

class SongDetailsScreen extends StatefulWidget {
  final Song song;

  const SongDetailsScreen({super.key, required this.song});

  @override
  State<SongDetailsScreen> createState() => _SongDetailsScreenState();
}

class _SongDetailsScreenState extends State<SongDetailsScreen> {
  List<LyricLine> _lyrics = [];
  bool _isLoadingLyrics = true;

  @override
  void initState() {
    super.initState();
    _loadLyrics();
  }

  Future<void> _loadLyrics() async {
    // 1. Check local verified asset first
    if (widget.song.lyricsPath != null && widget.song.lyricsPath!.isNotEmpty) {
      final lines = await LyricsService.loadLyricsFromAsset(widget.song.lyricsPath!);
      if (lines.isNotEmpty && mounted) {
        setState(() {
          _lyrics = lines;
          _isLoadingLyrics = false;
        });
        return;
      }
    }

    // 2. Query LRCLIB service (exact -> search -> cache)
    final result = await LrclibService.fetchLyrics(
      title: widget.song.title,
      artist: widget.song.artist,
      album: widget.song.movieOrAlbum,
      durationSeconds: widget.song.duration.inSeconds,
    );

    if (mounted) {
      setState(() {
        if (result.isSynced && result.lyrics.isNotEmpty) {
          _lyrics = result.lyrics;
        } else if (result.plainLyrics != null && result.plainLyrics!.isNotEmpty) {
          final plainLines = result.plainLyrics!
              .split('\n')
              .map((l) => l.trim())
              .where((l) => l.isNotEmpty)
              .map((l) => LyricLine(timestamp: Duration.zero, text: l))
              .toList();
          _lyrics = plainLines;
        } else {
          _lyrics = [];
        }
        _isLoadingLyrics = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final playlist = context.watch<PlaylistService>();
    final audio = context.watch<AudioPlayerService>();
    final isFav = playlist.isFavorite(widget.song.id);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Song Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.playlist_add),
            tooltip: 'Add to Playlist',
            color: AppColors.primary,
            onPressed: () => AddToPlaylistDialog.show(context, widget.song),
          ),
          IconButton(
            icon: Icon(
              isFav ? Icons.favorite : Icons.favorite_border,
              color: isFav ? AppColors.accent : AppColors.textPrimary,
            ),
            onPressed: () => playlist.toggleFavorite(widget.song.id),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover Art
              Center(
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withAlpha(50),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      widget.song.coverImage,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: AppColors.surfaceHover,
                        child: const Icon(Icons.music_note, size: 80, color: AppColors.primary),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Title & Artist
              Text(
                widget.song.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.song.artist,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 20),

              // Action Buttons Row (Play Vocals vs Sing Karaoke)
              if (!widget.song.isPlayable)
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.orange.withAlpha(25),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.orange.withAlpha(80)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lock_outline, color: Colors.orange, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.song.audioSourceNotice ??
                              'Commercial film track — streaming rights reserved by label. Stream our licensed catalogue tracks to listen!',
                          style: const TextStyle(fontSize: 12, color: Colors.orange, height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ),

              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: widget.song.isPlayable ? AppColors.primaryGradient : null,
                        color: widget.song.isPlayable ? null : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(14),
                        border: widget.song.isPlayable ? null : Border.all(color: AppColors.border),
                      ),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: Icon(
                          widget.song.isPlayable ? Icons.play_arrow : Icons.lock_outline,
                          color: widget.song.isPlayable ? Colors.black : AppColors.textMuted,
                        ),
                        label: Text(
                          widget.song.isPlayable ? 'Play Vocals' : 'License Required',
                          style: TextStyle(
                            color: widget.song.isPlayable ? Colors.black : AppColors.textMuted,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: () {
                          if (!widget.song.isPlayable) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(widget.song.audioSourceNotice ?? 'Streaming license required for this track.'),
                                duration: const Duration(seconds: 3),
                              ),
                            );
                            return;
                          }
                          playlist.playSong(widget.song, audio, mode: PlaybackMode.normal);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const FullPlayerScreen()),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: widget.song.isPlayable
                            ? AppColors.karaokeGradient
                            : null,
                        color: widget.song.isPlayable
                            ? null
                            : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(14),
                        border: widget.song.isPlayable
                            ? null
                            : Border.all(color: AppColors.border),
                      ),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: Icon(
                          widget.song.isPlayable
                              ? (widget.song.isKaraokeAvailable ? Icons.mic : Icons.mic_external_on)
                              : Icons.mic_off_outlined,
                          color: widget.song.isPlayable
                              ? Colors.black
                              : AppColors.textMuted,
                        ),
                        label: Text(
                          !widget.song.isPlayable
                              ? 'License Required'
                              : (widget.song.isKaraokeAvailable ? 'Sing Karaoke' : 'Sing Along'),
                          style: TextStyle(
                            color: widget.song.isPlayable
                                ? Colors.black
                                : AppColors.textMuted,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        onPressed: () {
                          if (!widget.song.isPlayable) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(widget.song.audioSourceNotice ?? 'Streaming license required for this track.'),
                              ),
                            );
                            return;
                          }
                          // If karaoke instrumental stem is available, start in karaoke mode;
                          // Otherwise play vocal track and open Karaoke Stage for synchronized lyric sing-along!
                          final mode = widget.song.isKaraokeAvailable ? PlaybackMode.karaoke : PlaybackMode.normal;
                          playlist.playSong(widget.song, audio, mode: mode);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const KaraokePlayerScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Metadata Cards Grid
              const Text(
                'Song Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _infoRow('Movie / Album', widget.song.movieOrAlbum),
                    const Divider(color: AppColors.border, height: 20),
                    _infoRow('Language', widget.song.language),
                    const Divider(color: AppColors.border, height: 20),
                    _infoRow('Release Year', widget.song.year.toString()),
                    const Divider(color: AppColors.border, height: 20),
                    _infoRow('Genre', widget.song.genre),
                    const Divider(color: AppColors.border, height: 20),
                    _infoRow('Karaoke Available', widget.song.isKaraokeAvailable ? 'Yes (Instrumental Track)' : 'No'),
                    const Divider(color: AppColors.border, height: 20),
                    _infoRow('Normal Audio Asset', widget.song.normalAudioPath.isEmpty ? 'License Required' : widget.song.normalAudioPath),
                    const Divider(color: AppColors.border, height: 20),
                    _infoRow('Karaoke Audio Asset', widget.song.karaokeAudioPath ?? (widget.song.isPlayable ? 'Vocal sing-along mode' : 'License Required')),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Lyrics Preview
              const Text(
                'Lyrics Preview',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: _isLoadingLyrics
                    ? const Center(child: CircularProgressIndicator())
                    : _lyrics.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              widget.song.genre.contains('Classical') && !widget.song.hasTimedLyrics
                                  ? 'Instrumental classical composition (no vocal lyrics).'
                                  : 'Lyrics not available for "${widget.song.title}" on LRCLIB or local assets.',
                              style: const TextStyle(fontSize: 13, color: AppColors.textMuted, fontStyle: FontStyle.italic),
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _lyrics.take(6).map((line) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Text(
                                  line.text,
                                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                ),
                              );
                            }).toList(),
                          ),
              ),

              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
