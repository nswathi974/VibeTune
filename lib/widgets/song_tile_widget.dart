import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song_model.dart';
import '../services/audio_player_service.dart';
import '../services/playlist_service.dart';
import '../theme/app_colors.dart';
import '../screens/song_details_screen.dart';
import '../screens/player/full_player_screen.dart';
import 'add_to_playlist_dialog.dart';

class SongTileWidget extends StatelessWidget {
  final Song song;
  final VoidCallback? onTap;

  const SongTileWidget({
    super.key,
    required this.song,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final audioService = context.watch<AudioPlayerService>();
    final playlistService = context.watch<PlaylistService>();

    final isCurrent = audioService.currentSong?.id == song.id;
    final isPlaying = isCurrent && audioService.isPlaying;
    final isFav = playlistService.isFavorite(song.id);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isCurrent
            ? (palette.isDark
                ? palette.surfaceElevated.withAlpha(220)
                : palette.primary.withAlpha(20))
            : (palette.isDark
                ? palette.surface.withAlpha(160)
                : palette.surface),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCurrent
              ? palette.primary.withAlpha(palette.isDark ? 140 : 180)
              : (palette.isDark
                  ? Colors.white.withAlpha(12)
                  : Colors.black.withAlpha(10)),
          width: isCurrent ? 1.4 : 1,
        ),
        boxShadow: [
          if (!palette.isDark && !isCurrent)
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            if (!song.isPlayable) {
              _showLicenseDialog(context, playlistService, audioService, palette);
              return;
            }

            if (onTap != null) {
              onTap!();
            } else {
              if (audioService.currentSong?.id == song.id) {
                if (!audioService.isPlaying) {
                  audioService.togglePlayPause();
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FullPlayerScreen()),
                );
              } else {
                playlistService.playSong(song, audioService);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FullPlayerScreen()),
                );
              }
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                // Thumbnail / Cover Art with Playing Indicator
                Stack(
                  alignment: Alignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 50,
                        height: 50,
                        color: palette.surfaceHover,
                        child: Image.asset(
                          song.coverImage,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            decoration: BoxDecoration(
                              gradient: palette.cardGradient,
                            ),
                            child: Icon(
                              Icons.music_note_rounded,
                              color: palette.textMuted,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (isCurrent)
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(140),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Icon(
                            isPlaying ? Icons.graphic_eq_rounded : Icons.play_arrow_rounded,
                            color: palette.primary,
                            size: 24,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(width: 12),

                // Title & Subtitle Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isCurrent ? palette.primary : palette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${song.artist} • ${song.movieOrAlbum}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: palette.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          // Language Chip
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: palette.surfaceHover,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              song.language,
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                                color: palette.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),

                          // Badges: Karaoke Ready / YouTube Stream / Playable / License Required
                          if (song.isKaraokeAvailable)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: palette.karaokeAccent.withAlpha(palette.isDark ? 30 : 25),
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(
                                  color: palette.karaokeAccent.withAlpha(palette.isDark ? 90 : 120),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.mic_rounded,
                                    size: 10,
                                    color: palette.karaokeAccent,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    'Karaoke Ready',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                      color: palette.karaokeAccent,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else if (song.isYouTubeTrack)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withAlpha(palette.isDark ? 25 : 20),
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(
                                  color: Colors.redAccent.withAlpha(palette.isDark ? 90 : 120),
                                  width: 0.8,
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.play_circle_fill_rounded,
                                    size: 10,
                                    color: Colors.redAccent,
                                  ),
                                  SizedBox(width: 3),
                                  Text(
                                    'YouTube Stream',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else if (song.isPlayable)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: palette.primary.withAlpha(palette.isDark ? 25 : 20),
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(
                                  color: palette.primary.withAlpha(palette.isDark ? 80 : 120),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.graphic_eq_rounded,
                                    size: 10,
                                    color: palette.primary,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    'Playable Stream',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                      color: palette.primary,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: palette.warning.withAlpha(palette.isDark ? 20 : 15),
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(
                                  color: palette.warning.withAlpha(palette.isDark ? 70 : 100),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.lock_outline_rounded,
                                    size: 10,
                                    color: palette.warning,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    'License Required',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w600,
                                      color: palette.warning,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Favorite Heart Button
                IconButton(
                  icon: Icon(
                    isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    size: 20,
                    color: isFav ? palette.accent : palette.textMuted,
                  ),
                  onPressed: () {
                    playlistService.toggleFavorite(song.id);
                  },
                ),

                // Actions Menu
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert_rounded,
                    size: 20,
                    color: palette.textMuted,
                  ),
                  color: palette.surfaceElevated,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: palette.border),
                  ),
                  onSelected: (value) {
                    if (value == 'playlist') {
                      AddToPlaylistDialog.show(context, song);
                    } else if (value == 'details') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SongDetailsScreen(song: song),
                        ),
                      );
                    }
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: 'playlist',
                      child: Row(
                        children: [
                          Icon(Icons.playlist_add_rounded, color: palette.primary, size: 18),
                          const SizedBox(width: 10),
                          Text('Add to Playlist', style: TextStyle(color: palette.textPrimary, fontSize: 13)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'details',
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded, color: palette.textSecondary, size: 18),
                          const SizedBox(width: 10),
                          Text('Song Details', style: TextStyle(color: palette.textPrimary, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLicenseDialog(
    BuildContext context,
    PlaylistService playlistService,
    AudioPlayerService audioService,
    AppPalette palette,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: palette.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: palette.border),
        ),
        title: Row(
          children: [
            Icon(Icons.lock_outline_rounded, color: palette.warning, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                song.title,
                style: TextStyle(
                  color: palette.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${song.artist} • ${song.movieOrAlbum}',
              style: TextStyle(color: palette.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Text(
              song.audioSourceNotice ??
                  'Commercial film soundtrack — streaming rights reserved by label.',
              style: TextStyle(color: palette.textPrimary, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: palette.surfaceHover,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: palette.border),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: palette.primary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Listen to our verified licensed classical, folk & studio tracks to enjoy full streaming & karaoke!',
                      style: TextStyle(color: palette.textSecondary, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Close', style: TextStyle(color: palette.textMuted)),
          ),
          TextButton.icon(
            icon: Icon(Icons.lyrics_outlined, size: 16, color: palette.primary),
            label: Text('View Lyrics', style: TextStyle(color: palette.primary, fontWeight: FontWeight.bold)),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SongDetailsScreen(song: song),
                ),
              );
            },
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: palette.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.play_arrow_rounded, size: 18),
            label: const Text('Play Licensed Track', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () {
              Navigator.pop(ctx);
              final playableTrack = playlistService.allSongs.firstWhere(
                (s) => s.isPlayable && s.language.toLowerCase() == song.language.toLowerCase(),
                orElse: () => playlistService.allSongs.firstWhere((s) => s.isPlayable),
              );
              playlistService.playSong(playableTrack, audioService);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FullPlayerScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}
