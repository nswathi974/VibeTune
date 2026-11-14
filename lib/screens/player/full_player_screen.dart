import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import '../../services/audio_player_service.dart';
import '../../services/playlist_service.dart';
import '../../models/song_model.dart';
import '../../theme/app_colors.dart';
import '../../widgets/lyrics_view_widget.dart';
import '../../widgets/mode_switch_widget.dart';
import '../../widgets/vibetune_youtube_player.dart';
import 'karaoke_player_screen.dart';

class FullPlayerScreen extends StatefulWidget {
  final bool startInKaraoke;

  const FullPlayerScreen({super.key, this.startInKaraoke = false});

  @override
  State<FullPlayerScreen> createState() => _FullPlayerScreenState();
}

class _FullPlayerScreenState extends State<FullPlayerScreen> {
  double? _dragValue;
  bool _showLyrics = false;

  @override
  void initState() {
    super.initState();
    _showLyrics = widget.startInKaraoke;
    if (widget.startInKaraoke) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final audio = context.read<AudioPlayerService>();
        if (audio.currentSong?.isKaraokeAvailable == true &&
            audio.playbackMode != PlaybackMode.karaoke) {
          audio.toggleMode();
        }
      });
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final audio = context.watch<AudioPlayerService>();
    final playlist = context.watch<PlaylistService>();

    final song = audio.currentSong;
    if (song == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(
          child: Text('No song currently loaded', style: TextStyle(color: AppColors.textPrimary)),
        ),
      );
    }

    final isKaraoke = audio.isKaraokeMode;
    final isFav = playlist.isFavorite(song.id);

    final position = audio.position;
    final duration = audio.duration.inMilliseconds > 0 ? audio.duration : song.duration;
    final sliderMax = duration.inMilliseconds.toDouble();
    final sliderValue = (_dragValue ?? position.inMilliseconds.toDouble()).clamp(0.0, sliderMax);
    final isCurrentRoute = ModalRoute.of(context)?.isCurrent ?? true;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_down, size: 30, color: AppColors.textPrimary),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Column(
                    children: [
                      const Text(
                        'PLAYING FROM CATALOG',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                          color: AppColors.textMuted,
                        ),
                      ),
                      Text(
                        song.language,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          _showLyrics ? Icons.image_outlined : Icons.lyrics_outlined,
                          color: _showLyrics ? AppColors.primary : AppColors.textPrimary,
                        ),
                        tooltip: _showLyrics ? 'Show Artwork' : 'Show Synchronized Lyrics',
                        onPressed: () => setState(() => _showLyrics = !_showLyrics),
                      ),
                      IconButton(
                        icon: Icon(
                          isFav ? Icons.favorite : Icons.favorite_border,
                          color: isFav ? AppColors.accent : AppColors.textPrimary,
                        ),
                        onPressed: () => playlist.toggleFavorite(song.id),
                      ),
                    ],
                  ),
                ],
              ),

              const Spacer(flex: 1),

              // Display: YouTube IFrame Player (Policy-Compliant Visible Viewport) or Local Artwork / Lyrics
              if (song.isYouTubeTrack && audio.youtubeController != null && isCurrentRoute)
                if (_showLyrics)
                  Expanded(
                    flex: 14,
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: VibeTuneYouTubePlayer(
                            key: ValueKey('full_yt_lyrics_${song.id}'),
                            controller: audio.youtubeController!,
                            song: song,
                            aspectRatio: 16 / 9,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: const LyricsViewWidget(
                                isKaraoke: false,
                                allowTapToSeek: true,
                                showHeader: false,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Expanded(
                    flex: 14,
                    child: Center(
                      child: VibeTuneYouTubePlayer(
                        key: ValueKey('full_yt_nolyrics_${song.id}'),
                        controller: audio.youtubeController!,
                        song: song,
                        aspectRatio: 16 / 9,
                      ),
                    ),
                  )
              else if (_showLyrics)
                Expanded(
                  flex: 14,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: const LyricsViewWidget(
                        isKaraoke: false,
                        allowTapToSeek: true,
                      ),
                    ),
                  ),
                )
              else
                // Album Artwork Card with Mode Aura
                GestureDetector(
                  onTap: () => setState(() => _showLyrics = true),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: isKaraoke
                              ? AppColors.karaokeAccent.withAlpha(90)
                              : AppColors.primary.withAlpha(80),
                          blurRadius: 36,
                          spreadRadius: 2,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Image.asset(
                            song.coverImage,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (_, _, _) => Container(
                              decoration: BoxDecoration(
                                gradient: isKaraoke
                                    ? AppColors.karaokeGradient
                                    : AppColors.primaryGradient,
                              ),
                              child: Icon(
                                isKaraoke ? Icons.mic : Icons.music_note,
                                size: 100,
                                color: Colors.black45,
                              ),
                            ),
                          ),
                          if (isKaraoke)
                            Positioned(
                              top: 14,
                              right: 14,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withAlpha(180),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.karaokeAccent, width: 1),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.mic, size: 12, color: AppColors.karaokeAccent),
                                    SizedBox(width: 4),
                                    Text(
                                      'KARAOKE ON',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.karaokeAccent,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

              const Spacer(flex: 1),

              // Song Info
              Column(
                children: [
                  Text(
                    song.title,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${song.artist} • ${song.movieOrAlbum}',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Mode Switcher Widget (Normal Vocals <-> Karaoke Instrumental) or YouTube Sing-Along Badge
              if (!song.isYouTubeTrack)
                ModeSwitchWidget(
                  currentMode: audio.playbackMode,
                  isKaraokeAvailable: song.isKaraokeAvailable,
                  onModeChanged: (newMode) {
                    audio.setPlaybackMode(newMode);
                  },
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withAlpha(25),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.redAccent.withAlpha(100)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.mic, size: 16, color: Colors.redAccent),
                      SizedBox(width: 8),
                      Text(
                        'YouTube Sing-Along • Real-Time Synced Lyrics',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

              if (audio.playbackErrorMessage != null || !song.isPlayable)
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withAlpha(80)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 16, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          audio.playbackErrorMessage ?? song.audioSourceNotice ?? 'Streaming license required for this track.',
                          style: const TextStyle(fontSize: 11, color: Colors.orange),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 12),

              // Seek Bar & Timestamps
              Column(
                children: [
                  Slider(
                    value: sliderValue,
                    min: 0.0,
                    max: sliderMax > 0 ? sliderMax : 1.0,
                    activeColor: isKaraoke ? AppColors.karaokeAccent : AppColors.primary,
                    inactiveColor: AppColors.surfaceHover,
                    onChanged: (val) {
                      setState(() => _dragValue = val);
                    },
                    onChangeEnd: (val) {
                      audio.seek(Duration(milliseconds: val.toInt()));
                      setState(() => _dragValue = null);
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(position),
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                        Text(
                          _formatDuration(duration),
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Playback Controls Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Shuffle
                  IconButton(
                    icon: Icon(
                      Icons.shuffle,
                      size: 22,
                      color: audio.isShuffle ? AppColors.primary : AppColors.textMuted,
                    ),
                    onPressed: () => audio.toggleShuffle(),
                  ),

                  // Previous
                  IconButton(
                    icon: const Icon(
                      Icons.skip_previous,
                      size: 38,
                      color: AppColors.textPrimary,
                    ),
                    onPressed: () => playlist.previousSong(audio),
                  ),

                  // Play / Pause (Big Circular Button)
                  GestureDetector(
                    onTap: () => audio.togglePlayPause(),
                    child: Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: isKaraoke
                            ? AppColors.karaokeGradient
                            : AppColors.primaryGradient,
                        boxShadow: [
                          BoxShadow(
                            color: (isKaraoke ? AppColors.karaokeAccent : AppColors.primary)
                                .withAlpha(120),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: audio.isLoading
                            ? const CircularProgressIndicator(color: Colors.black, strokeWidth: 3)
                            : Icon(
                                audio.isPlaying ? Icons.pause : Icons.play_arrow,
                                size: 36,
                                color: Colors.black,
                              ),
                      ),
                    ),
                  ),

                  // Next
                  IconButton(
                    icon: const Icon(
                      Icons.skip_next,
                      size: 38,
                      color: AppColors.textPrimary,
                    ),
                    onPressed: () => playlist.nextSong(audio),
                  ),

                  // Loop Mode
                  IconButton(
                    icon: Icon(
                      audio.loopMode == LoopMode.one
                          ? Icons.repeat_one
                          : (audio.loopMode == LoopMode.all ? Icons.repeat : Icons.repeat),
                      size: 22,
                      color: audio.loopMode != LoopMode.off
                          ? AppColors.primary
                          : AppColors.textMuted,
                    ),
                    onPressed: () => audio.cycleLoopMode(),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Button to Open Karaoke Stage Screen
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isKaraoke ? AppColors.karaokeAccent : AppColors.border,
                    width: isKaraoke ? 1.5 : 1,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: ListTile(
                    dense: true,
                    leading: Icon(
                      Icons.mic,
                      color: isKaraoke ? AppColors.karaokeAccent : AppColors.primary,
                    ),
                    title: Text(
                      isKaraoke ? 'Karaoke Stage Active (Tap to View)' : '🎤 Enter Karaoke Stage',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isKaraoke ? AppColors.karaokeAccent : AppColors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      song.isKaraokeAvailable
                          ? 'Full synchronized lyrics & instrumental stem'
                          : 'Sing along with vocal audio & synchronized lyrics',
                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
                    onTap: () {
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
        ),
      ),
    );
  }
}
