import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/audio_player_service.dart';
import '../../services/playlist_service.dart';
import '../../services/separation_service.dart';
import '../../services/auth_service.dart';
import '../../models/song_model.dart';
import '../../models/separation_job_model.dart';
import '../../theme/app_colors.dart';
import '../../widgets/mode_switch_widget.dart';
import '../../widgets/lyrics_view_widget.dart';
import '../../widgets/vibetune_youtube_player.dart';
import 'full_player_screen.dart';

class KaraokePlayerScreen extends StatefulWidget {
  final bool isEmbedded;
  final bool isActiveTab;

  const KaraokePlayerScreen({
    super.key,
    this.isEmbedded = false,
    this.isActiveTab = true,
  });

  @override
  State<KaraokePlayerScreen> createState() => _KaraokePlayerScreenState();
}

class _KaraokePlayerScreenState extends State<KaraokePlayerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final audio = context.read<AudioPlayerService>();
      if (audio.currentSong?.isKaraokeAvailable == true) {
        if (audio.playbackMode != PlaybackMode.karaoke) {
          audio.setPlaybackMode(PlaybackMode.karaoke);
        }
      }
    });
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
        backgroundColor: const Color(0xFF07090E),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: widget.isEmbedded
              ? null
              : IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
          title: const Row(
            children: [
              Icon(Icons.mic, color: AppColors.karaokeAccent, size: 22),
              SizedBox(width: 8),
              Text(
                'Karaoke Stage',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.karaokeAccent.withAlpha(50),
                        AppColors.surface,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.karaokeAccent.withAlpha(120)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.stars, color: AppColors.karaokeAccent, size: 36),
                      SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Step into the Spotlight',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Choose a track below to begin singing with synchronized lyrics & genuine backing stems.',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Select a Track for Karaoke Stage',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    itemCount: playlist.allSongs.where((s) => s.isPlayable).length,
                    itemBuilder: (context, idx) {
                      final playableSongs = playlist.allSongs.where((s) => s.isPlayable).toList();
                      final s = playableSongs[idx];
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.asset(
                              s.coverImage,
                              width: 44,
                              height: 44,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                width: 44,
                                height: 44,
                                color: AppColors.surfaceHover,
                                child: const Icon(Icons.music_note, color: AppColors.primary),
                              ),
                            ),
                          ),
                          title: Text(
                            s.title,
                            style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 14),
                          ),
                          subtitle: Text(
                            '${s.artist} • ${s.language}',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: s.isKaraokeAvailable
                                  ? AppColors.karaokeAccent.withAlpha(40)
                                  : AppColors.primary.withAlpha(40),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: s.isKaraokeAvailable
                                    ? AppColors.karaokeAccent
                                    : AppColors.primary,
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  s.isKaraokeAvailable ? Icons.mic : Icons.mic_external_on,
                                  size: 13,
                                  color: s.isKaraokeAvailable ? AppColors.karaokeAccent : AppColors.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  s.isKaraokeAvailable ? 'Instrumental' : 'Sing-Along',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: s.isKaraokeAvailable ? AppColors.karaokeAccent : AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          onTap: () {
                            playlist.playSong(
                              s,
                              audio,
                              mode: s.isKaraokeAvailable ? PlaybackMode.karaoke : PlaybackMode.normal,
                            );
                          },
                        ),
                      ),
                    );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final isKaraoke = audio.isKaraokeMode;
    final position = audio.position;
    final duration = audio.duration.inMilliseconds > 0 ? audio.duration : song.duration;
    final sliderMax = duration.inMilliseconds.toDouble();
    final sliderVal = position.inMilliseconds.toDouble().clamp(0.0, sliderMax);
    final isCurrentRoute = ModalRoute.of(context)?.isCurrent ?? true;
    final shouldRenderPlayer = widget.isActiveTab && isCurrentRoute;

    return Scaffold(
      backgroundColor: const Color(0xFF07090E),
      body: Stack(
        children: [
          // Background ambient spotlight
          Positioned(
            top: -120,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      (isKaraoke ? AppColors.karaokeAccent : AppColors.primary).withAlpha(40),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top Stage Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      if (!widget.isEmbedded)
                        IconButton(
                          icon: const Icon(Icons.keyboard_arrow_down, size: 28, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        )
                      else
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: Icon(Icons.mic, color: AppColors.karaokeAccent, size: 24),
                        ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              song.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              isKaraoke
                                  ? (audio.hasSecondaryTrack
                                      ? '🎤 Karaoke Instrumental Active'
                                      : '🎙️ Vocal Sing-Along Active (Stem Unavailable)')
                                  : (song.isKaraokeAvailable
                                      ? '🎙️ Vocal Track Active (Instrumental Available)'
                                      : '🎙️ Vocal Sing-Along Active (Archival Recording)'),
                              style: TextStyle(
                                fontSize: 11,
                                color: isKaraoke ? AppColors.karaokeAccent : AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Standard player shortcut
                      IconButton(
                        icon: const Icon(Icons.album_outlined, color: AppColors.textSecondary),
                        tooltip: 'Open Standard Player',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const FullPlayerScreen()),
                          );
                        },
                      ),
                      // Speed adjustment button
                      PopupMenuButton<double>(
                        icon: const Icon(Icons.speed, color: AppColors.textSecondary),
                        tooltip: 'Sing-along Speed',
                        onSelected: (speed) => audio.setSpeed(speed),
                        itemBuilder: (_) => [
                          const PopupMenuItem(value: 0.8, child: Text('0.8x (Slow practice)')),
                          const PopupMenuItem(value: 1.0, child: Text('1.0x (Normal speed)')),
                          const PopupMenuItem(value: 1.2, child: Text('1.2x (Fast tempo)')),
                        ],
                      ),
                    ],
                  ),
                ),

                // Visible YouTube Player or Local Mode Toggle
                if (song.isYouTubeTrack && audio.youtubeController != null && shouldRenderPlayer) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: VibeTuneYouTubePlayer(
                        key: ValueKey('karaoke_yt_${song.id}'),
                        controller: audio.youtubeController!,
                        song: song,
                        aspectRatio: 16 / 9,
                      ),
                    ),
                  ),
                ] else ...[
                  // Mode Toggle in Stage View for local audio
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: ModeSwitchWidget(
                      compact: true,
                      currentMode: audio.playbackMode,
                      isKaraokeAvailable: song.isKaraokeAvailable,
                      onModeChanged: (newMode) => audio.setPlaybackMode(newMode),
                    ),
                  ),
                  // AI Vocal Separation Banner
                  _buildAISeparationBanner(context, song, audio),
                ],

                // Lyrics Screen (Synchronized real-time highlighting)
                Expanded(
                  child: LyricsViewWidget(
                    isKaraoke: isKaraoke,
                    allowTapToSeek: true,
                  ),
                ),

                // Bottom Player Controls Bar
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withAlpha(240),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Slider & Times
                      Row(
                        children: [
                          Text(
                            _formatDuration(position),
                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                          ),
                          Expanded(
                            child: Slider(
                              value: sliderVal,
                              min: 0.0,
                              max: sliderMax > 0 ? sliderMax : 1.0,
                              activeColor: isKaraoke ? AppColors.karaokeAccent : AppColors.primary,
                              inactiveColor: AppColors.surfaceHover,
                              onChanged: (val) {
                                audio.seek(Duration(milliseconds: val.toInt()));
                              },
                            ),
                          ),
                          Text(
                            _formatDuration(duration),
                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                          ),
                        ],
                      ),

                      // Controls
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.skip_previous, size: 32, color: Colors.white),
                            onPressed: () => playlist.previousSong(audio),
                          ),
                          const SizedBox(width: 20),
                          GestureDetector(
                            onTap: () => audio.togglePlayPause(),
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: isKaraoke
                                    ? AppColors.karaokeGradient
                                    : AppColors.primaryGradient,
                              ),
                              child: Center(
                                child: audio.isLoading
                                    ? const CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5)
                                    : Icon(
                                        audio.isPlaying ? Icons.pause : Icons.play_arrow,
                                        size: 32,
                                        color: Colors.black,
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          IconButton(
                            icon: const Icon(Icons.skip_next, size: 32, color: Colors.white),
                            onPressed: () => playlist.nextSong(audio),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAISeparationBanner(
    BuildContext context,
    Song song,
    AudioPlayerService audio,
  ) {
    // Only show AI separation for authorized studio demo tracks (exclude commercial tracks)
    final isAuthorizedDemo = song.id.startsWith('vt_');
    if (!isAuthorizedDemo) return const SizedBox.shrink();

    final separation = context.watch<SeparationService>();
    final auth = context.read<AuthService>();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: separation.isProcessing
              ? AppColors.karaokeAccent.withAlpha(160)
              : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                size: 16,
                color: separation.status == SeparationStatus.completed
                    ? Colors.green
                    : AppColors.karaokeAccent,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  separation.isProcessing
                      ? 'AI Demucs Separating Vocals (${separation.progress}%)'
                      : (separation.status == SeparationStatus.completed
                          ? 'AI Instrumental Ready'
                          : 'Hosted AI Vocal Separation (Demucs)'),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              if (separation.isProcessing)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.karaokeAccent,
                  ),
                )
              else if (separation.status == SeparationStatus.completed)
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    backgroundColor: AppColors.karaokeAccent.withAlpha(40),
                  ),
                  onPressed: () {
                    if (separation.currentJob?.instrumentalUrl != null) {
                      audio.loadDynamicKaraokeStem(separation.currentJob!.instrumentalUrl!);
                    }
                  },
                  child: const Text(
                    'Load Stem',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.karaokeAccent,
                    ),
                  ),
                )
              else
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    backgroundColor: AppColors.primary.withAlpha(40),
                  ),
                  onPressed: () {
                    separation.requestSeparation(
                      song.id,
                      authToken: auth.token,
                      isGuest: !auth.isAuthenticated,
                      onCompleted: (job) {
                        if (job.instrumentalUrl != null) {
                          audio.loadDynamicKaraokeStem(job.instrumentalUrl!);
                        }
                      },
                    );
                  },
                  child: const Text(
                    'Separate',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
          if (separation.isProcessing) ...[
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: separation.progress > 0 ? separation.progress / 100.0 : null,
              backgroundColor: Colors.white10,
              color: AppColors.karaokeAccent,
              minHeight: 2,
            ),
          ],
          if (separation.errorMessage != null) ...[
            const SizedBox(height: 4),
            Text(
              separation.errorMessage!,
              style: const TextStyle(fontSize: 10, color: Colors.amberAccent),
            ),
          ],
        ],
      ),
    );
  }
}
