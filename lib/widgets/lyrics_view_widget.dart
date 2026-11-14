import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/audio_player_service.dart';
import '../services/translation_service.dart';
import '../theme/app_colors.dart';

class LyricsViewWidget extends StatefulWidget {
  final bool isKaraoke;
  final bool allowTapToSeek;
  final bool showHeader;

  const LyricsViewWidget({
    super.key,
    this.isKaraoke = true,
    this.allowTapToSeek = true,
    this.showHeader = true,
  });

  @override
  State<LyricsViewWidget> createState() => _LyricsViewWidgetState();
}

class _LyricsViewWidgetState extends State<LyricsViewWidget> {
  final ScrollController _scrollController = ScrollController();
  int _lastActiveIndex = -1;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToActiveIndex(int index, int totalLines) {
    if (!_scrollController.hasClients || index < 0 || index >= totalLines) return;

    // Approximate height per lyric row = 64px
    const itemHeight = 64.0;
    final screenHeight = MediaQuery.of(context).size.height;
    final targetOffset = (index * itemHeight) - (screenHeight * 0.28);

    _scrollController.animateTo(
      targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final audio = context.watch<AudioPlayerService>();
    final lyrics = audio.currentLyrics;
    final plainLyrics = audio.plainLyrics;
    final activeIndex = audio.activeLyricIndex;
    final currentSong = audio.currentSong;
    final activeColor = widget.isKaraoke ? AppColors.karaokeAccent : AppColors.primary;

    if (audio.isSyncedLyrics && activeIndex != _lastActiveIndex) {
      _lastActiveIndex = activeIndex;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToActiveIndex(activeIndex, lyrics.length);
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showHeader) ...[
          // 1. Song Title & Artist Header
          if (currentSong != null)
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          currentSong.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${currentSong.artist} • ${currentSong.language}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Mode Indicator Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: audio.isSyncedLyrics
                          ? Colors.green.withAlpha(40)
                          : (plainLyrics != null && plainLyrics.isNotEmpty)
                              ? Colors.amber.withAlpha(40)
                              : Colors.grey.withAlpha(40),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: audio.isSyncedLyrics
                            ? Colors.green.withAlpha(140)
                            : (plainLyrics != null && plainLyrics.isNotEmpty)
                                ? Colors.amber.withAlpha(140)
                                : Colors.grey.withAlpha(100),
                      ),
                    ),
                    child: Text(
                      audio.isSyncedLyrics
                          ? 'SYNCED LRC'
                          : (plainLyrics != null && plainLyrics.isNotEmpty)
                              ? 'PLAIN LYRICS'
                              : 'NO LYRICS',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.6,
                        color: audio.isSyncedLyrics
                            ? Colors.greenAccent
                            : (plainLyrics != null && plainLyrics.isNotEmpty)
                                ? Colors.amberAccent
                                : AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // 2. Language Selector & Source Description Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Language Selection Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: TranslationService.supportedLanguages.keys.map((lang) {
                      final isSelected = audio.currentLyricLanguage == lang;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(lang),
                          selected: isSelected,
                          selectedColor: activeColor.withAlpha(60),
                          backgroundColor: AppColors.surface,
                          checkmarkColor: activeColor,
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? activeColor : AppColors.textSecondary,
                          ),
                          side: BorderSide(
                            color: isSelected ? activeColor : AppColors.border,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              audio.changeLyricLanguage(lang);
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 6),

                // Source and Synchronization Details
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        audio.lyricSourceDescription,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),

                    // LRCLIB Cloud Refresh Button
                    IconButton(
                      icon: const Icon(Icons.cloud_sync_outlined, size: 18, color: AppColors.textMuted),
                      tooltip: 'Fetch lyrics from LRCLIB API',
                      onPressed: audio.isTranslating ? null : () => audio.reloadLyricsFromLrclib(),
                    ),
                  ],
                ),

                // Translating Progress Bar
                if (audio.isTranslating)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: LinearProgressIndicator(
                      minHeight: 2,
                      color: AppColors.primary,
                      backgroundColor: Colors.transparent,
                    ),
                  ),
              ],
            ),
          ),

          const Divider(color: AppColors.border, height: 1),
        ],

        // 3. Main Lyrics Content Area
        Expanded(
          child: audio.isSyncedLyrics && lyrics.isNotEmpty
              // MODE A: Genuine Synchronized Lyrics
              ? ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
                  itemCount: lyrics.length,
                  itemBuilder: (context, index) {
                    final line = lyrics[index];
                    final isActive = index == activeIndex;
                    final isPast = index < activeIndex;

                    return GestureDetector(
                      onTap: widget.allowTapToSeek
                          ? () {
                              audio.seek(line.timestamp);
                            }
                          : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            if (isActive) ...[
                              Icon(
                                widget.isKaraoke ? Icons.mic : Icons.music_note,
                                size: 18,
                                color: activeColor,
                              ),
                              const SizedBox(width: 8),
                            ],
                            Expanded(
                              child: Text(
                                line.text,
                                textAlign: TextAlign.left,
                                style: TextStyle(
                                  fontSize: isActive
                                      ? (widget.isKaraoke ? 23 : 21)
                                      : (isPast ? 16 : 17),
                                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                                  color: isActive
                                      ? activeColor
                                      : (isPast
                                          ? AppColors.textMuted.withAlpha(160)
                                          : AppColors.textSecondary),
                                  shadows: isActive
                                      ? [
                                          Shadow(
                                            color: activeColor.withAlpha(140),
                                            blurRadius: 16,
                                          ),
                                        ]
                                      : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                )
              : (plainLyrics != null && plainLyrics.trim().isNotEmpty)
                  // MODE B: Genuine Plain Unsynchronized Lyrics (Scrollable, Clean Text)
                  ? SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.info_outline, size: 14, color: AppColors.warning),
                                SizedBox(width: 6),
                                Text(
                                  'Unsynchronized lyrics — scroll to read along',
                                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          SelectableText(
                            plainLyrics.trim(),
                            style: const TextStyle(
                              fontSize: 16,
                              height: 1.8,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 60),
                        ],
                      ),
                    )
                  // MODE C: Honest Empty State — No Lyrics Available
                  : Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              widget.isKaraoke ? Icons.mic_none : Icons.lyrics_outlined,
                              size: 44,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Lyrics not available for "${currentSong?.title ?? 'this track'}"',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Verified original lyrics could not be found on LRCLIB or local assets. Genuine lyrics only — no placeholder text.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.cloud_sync, size: 15),
                              label: const Text('Search Cloud Lyrics', style: TextStyle(fontSize: 11)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: activeColor,
                                side: BorderSide(color: activeColor),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              ),
                              onPressed: () => audio.reloadLyricsFromLrclib(),
                            ),
                          ],
                        ),
                      ),
                    ),
        ),
      ],
    );
  }
}
