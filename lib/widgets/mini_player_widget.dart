import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/audio_player_service.dart';
import '../services/playlist_service.dart';
import '../theme/app_colors.dart';
import '../screens/player/full_player_screen.dart';

class MiniPlayerWidget extends StatelessWidget {
  const MiniPlayerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final audio = context.watch<AudioPlayerService>();
    final playlist = context.watch<PlaylistService>();

    final song = audio.currentSong;
    if (song == null) {
      return const SizedBox.shrink();
    }

    final isKaraoke = audio.isKaraokeMode;
    final progress = audio.duration.inMilliseconds > 0
        ? (audio.position.inMilliseconds / audio.duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    final accentColor = song.isYouTubeTrack
        ? Colors.redAccent
        : (isKaraoke ? palette.karaokeAccent : palette.primary);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              color: palette.isDark
                  ? palette.surface.withAlpha(220)
                  : palette.surface.withAlpha(240),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: palette.isDark
                    ? Colors.white.withAlpha(20)
                    : Colors.black.withAlpha(15),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(palette.isDark ? 90 : 25),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const FullPlayerScreen(),
                    ),
                  );
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Sleek Top-edge Micro Progress Indicator
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 2.5,
                        backgroundColor: palette.isDark
                            ? Colors.white.withAlpha(15)
                            : Colors.black.withAlpha(10),
                        valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
                      child: Row(
                        children: [
                          // Album Artwork with soft rounded corners & ambient shadow
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: accentColor.withAlpha(palette.isDark ? 40 : 20),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.asset(
                                song.coverImage,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Container(
                                  decoration: BoxDecoration(
                                    gradient: isKaraoke
                                        ? palette.karaokeGradient
                                        : palette.primaryGradient,
                                  ),
                                  child: Icon(
                                    isKaraoke ? Icons.mic : Icons.music_note,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 10),

                          // Song Title, Artist & Source Pill
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    if (audio.isPlaying) ...[
                                      Icon(
                                        Icons.graphic_eq,
                                        size: 13,
                                        color: accentColor,
                                      ),
                                      const SizedBox(width: 4),
                                    ],
                                    Expanded(
                                      child: Text(
                                        song.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: palette.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: accentColor.withAlpha(palette.isDark ? 35 : 25),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        song.isYouTubeTrack
                                            ? 'YOUTUBE'
                                            : (isKaraoke ? 'KARAOKE' : 'VOCAL'),
                                        style: TextStyle(
                                          fontSize: 8.5,
                                          fontWeight: FontWeight.bold,
                                          color: accentColor,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        song.artist,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: palette.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Quick Mode Toggle Button (if dual-stem supported)
                          if (song.isKaraokeAvailable)
                            IconButton(
                              icon: Icon(
                                isKaraoke ? Icons.mic : Icons.mic_none,
                                size: 20,
                                color: isKaraoke ? palette.karaokeAccent : palette.textMuted,
                              ),
                              tooltip: isKaraoke ? 'Vocal Mode' : 'Karaoke Mode',
                              onPressed: () {
                                audio.toggleMode();
                              },
                            ),

                          // Play / Pause Button with responsive glowing state
                          IconButton(
                            icon: audio.isLoading
                                ? SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: accentColor,
                                    ),
                                  )
                                : Icon(
                                    audio.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                                    size: 36,
                                    color: accentColor,
                                  ),
                            onPressed: () {
                              audio.togglePlayPause();
                            },
                          ),

                          // Next Track Button
                          IconButton(
                            icon: Icon(
                              Icons.skip_next_rounded,
                              size: 24,
                              color: palette.textSecondary,
                            ),
                            onPressed: () {
                              playlist.nextSong(audio);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
