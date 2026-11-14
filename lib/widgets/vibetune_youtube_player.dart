import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../models/song_model.dart';
import '../theme/app_colors.dart';

/// VibeTuneYouTubePlayer
///
/// A policy-compliant visual player container embedding YouTube's official
/// IFrame Player. Complies strictly with YouTube Developer Policies:
/// - Player is fully visible on screen (Section III.D)
/// - Native advertisements, branding, and watermarks are unhindered (Section III.E)
/// - Views and ad revenue directly credit the original record labels
class VibeTuneYouTubePlayer extends StatelessWidget {
  final YoutubePlayerController controller;
  final Song song;
  final double aspectRatio;

  const VibeTuneYouTubePlayer({
    super.key,
    required this.controller,
    required this.song,
    this.aspectRatio = 16 / 9,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.redAccent.withAlpha(120), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.redAccent.withAlpha(60),
            blurRadius: 24,
            spreadRadius: 1,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // YouTube IFrame Player Viewport
          AspectRatio(
            aspectRatio: aspectRatio,
            child: YoutubePlayer(
              controller: controller,
              aspectRatio: aspectRatio,
            ),
          ),

          // Policy Attribution & Notice Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            color: const Color(0xFF11141C),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'YouTube Official Stream',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withAlpha(40),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Sing-Along Mode',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        song.audioSourceNotice ?? 'Monetization credited to copyright owner.',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 10,
                        ),
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
}

