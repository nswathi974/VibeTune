import 'package:flutter/material.dart';
import '../models/song_model.dart';
import '../theme/app_colors.dart';

class ModeSwitchWidget extends StatelessWidget {
  final PlaybackMode currentMode;
  final ValueChanged<PlaybackMode> onModeChanged;
  final bool compact;
  final bool isKaraokeAvailable;

  const ModeSwitchWidget({
    super.key,
    required this.currentMode,
    required this.onModeChanged,
    this.compact = false,
    this.isKaraokeAvailable = true,
  });

  @override
  Widget build(BuildContext context) {
    final isNormal = currentMode == PlaybackMode.normal;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Normal Vocal Option
          GestureDetector(
            onTap: () => onModeChanged(PlaybackMode.normal),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 12 : 18,
                vertical: compact ? 6 : 10,
              ),
              decoration: BoxDecoration(
                gradient: isNormal ? AppColors.primaryGradient : null,
                borderRadius: BorderRadius.circular(25),
                boxShadow: isNormal
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withAlpha(90),
                          blurRadius: 12,
                          offset: const Offset(0, 3),
                        )
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.graphic_eq,
                    size: compact ? 14 : 18,
                    color: isNormal ? Colors.black : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Normal (Vocals)',
                    style: TextStyle(
                      fontSize: compact ? 12 : 13,
                      fontWeight: isNormal ? FontWeight.bold : FontWeight.w500,
                      color: isNormal ? Colors.black : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 4),

          // Karaoke Instrumental Option
          GestureDetector(
            onTap: () {
              if (!isKaraokeAvailable) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Karaoke instrumental stem is not available for this track (no synthetic track fabricated).'),
                    duration: Duration(seconds: 2),
                  ),
                );
                return;
              }
              onModeChanged(PlaybackMode.karaoke);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 12 : 18,
                vertical: compact ? 6 : 10,
              ),
              decoration: BoxDecoration(
                gradient: !isNormal && isKaraokeAvailable ? AppColors.karaokeGradient : null,
                borderRadius: BorderRadius.circular(25),
                boxShadow: !isNormal && isKaraokeAvailable
                    ? [
                        BoxShadow(
                          color: AppColors.karaokeAccent.withAlpha(110),
                          blurRadius: 14,
                          offset: const Offset(0, 3),
                        )
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isKaraokeAvailable ? Icons.mic_external_on : Icons.mic_off_outlined,
                    size: compact ? 14 : 18,
                    color: !isNormal
                        ? Colors.black
                        : (isKaraokeAvailable ? AppColors.karaokeAccent : AppColors.textMuted),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isKaraokeAvailable ? 'Karaoke Mode' : 'Karaoke N/A',
                    style: TextStyle(
                      fontSize: compact ? 12 : 13,
                      fontWeight: !isNormal ? FontWeight.bold : FontWeight.w600,
                      color: !isNormal
                          ? Colors.black
                          : (isKaraokeAvailable ? AppColors.karaokeAccent : AppColors.textMuted),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
