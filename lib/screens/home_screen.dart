import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/audio_player_service.dart';
import '../services/playlist_service.dart';
import '../services/auth_service.dart';
import '../models/song_model.dart';
import '../data/song_catalog.dart';
import '../theme/app_colors.dart';
import '../widgets/song_tile_widget.dart';
import 'player/full_player_screen.dart';
import 'player/karaoke_player_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final auth = context.watch<AuthService>();
    final playlist = context.watch<PlaylistService>();
    final audio = context.watch<AudioPlayerService>();

    final featuredSong = SongCatalog.allSongs.isNotEmpty ? SongCatalog.allSongs.first : null;
    final userName = auth.currentUser?.name ?? 'Guest Explorer';

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Top App Bar / Greeting Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: palette.primary,
                              width: 1.8,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: palette.primary.withAlpha(palette.isDark ? 50 : 25),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/logo.png',
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Icon(
                                Icons.person_rounded,
                                color: palette.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Namaste, $userName 👋',
                              style: TextStyle(
                                fontSize: 16.5,
                                fontWeight: FontWeight.w700,
                                color: palette.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'What would you like to sing today?',
                              style: TextStyle(
                                fontSize: 12,
                                color: palette.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: palette.surfaceElevated,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: palette.border),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.graphic_eq_rounded, size: 14, color: palette.primary),
                          const SizedBox(width: 5),
                          Text(
                            'VibeTune',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: palette.primary,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Hero Featured Spotlight Card
            if (featuredSong != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Container(
                    height: 220,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: palette.secondary.withAlpha(palette.isDark ? 50 : 25),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      children: [
                        // Background Artwork
                        Positioned.fill(
                          child: Image.asset(
                            featuredSong.coverImage,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              color: palette.surfaceHover,
                            ),
                          ),
                        ),

                        // Atmospheric Gradient Overlay
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.black.withAlpha(240),
                                  Colors.black.withAlpha(160),
                                  Colors.black.withAlpha(40),
                                  Colors.transparent,
                                ],
                                stops: const [0.0, 0.45, 0.8, 1.0],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                            ),
                          ),
                        ),

                        // Spotlight Details & Action Buttons
                        Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                                decoration: BoxDecoration(
                                  color: palette.accent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'FEATURED SPOTLIGHT',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                featuredSong.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 21,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${featuredSong.artist} • ${featuredSong.movieOrAlbum}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: Colors.white.withAlpha(200),
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Real action buttons: Play Vocals vs Sing Karaoke
                              Row(
                                children: [
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: palette.primary,
                                      foregroundColor: Colors.black,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    icon: const Icon(Icons.play_arrow_rounded, size: 20),
                                    label: const Text(
                                      'Play Vocals',
                                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                                    ),
                                    onPressed: () {
                                      playlist.playSong(featuredSong, audio, mode: PlaybackMode.normal);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => const FullPlayerScreen()),
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 10),
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: Colors.black.withAlpha(140),
                                      foregroundColor: palette.karaokeAccent,
                                      side: BorderSide(
                                        color: palette.karaokeAccent,
                                        width: 1.4,
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    icon: Icon(Icons.mic_rounded, size: 18, color: palette.karaokeAccent),
                                    label: const Text(
                                      'Sing Karaoke',
                                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                                    ),
                                    onPressed: () {
                                      playlist.playSong(featuredSong, audio, mode: PlaybackMode.karaoke);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const KaraokePlayerScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
            else
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Container(
                    height: 140,
                    decoration: BoxDecoration(
                      color: palette.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: palette.border),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.queue_music_rounded, size: 36, color: palette.primary),
                          const SizedBox(height: 8),
                          Text(
                            'Ready for Your Songs',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: palette.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Previous songs removed. Ready to add your songs!',
                            style: TextStyle(fontSize: 12, color: palette.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // Horizontal Language Selector Chips
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: SongCatalog.availableLanguages.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final lang = SongCatalog.availableLanguages[index];
                      final isSelected = playlist.selectedLanguage == lang;

                      return ChoiceChip(
                        label: Text(lang),
                        selected: isSelected,
                        selectedColor: palette.primary,
                        backgroundColor: palette.surfaceElevated,
                        showCheckmark: false,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? Colors.black : palette.textSecondary,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected ? palette.primary : palette.border,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        onSelected: (_) {
                          playlist.setLanguage(lang);
                        },
                      );
                    },
                  ),
                ),
              ),
            ),

            // Language-Divided Sections & Karaoke Ready Shelf

            // 1. Karaoke Ready Shelf (Featured if 'All' or if karaoke songs available)
            if (playlist.selectedLanguage == 'All' && playlist.karaokeSongs.isNotEmpty) ...[
              _buildShelfHeader(
                palette,
                title: 'Karaoke Ready Tracks',
                icon: Icons.mic_external_on_rounded,
                iconColor: palette.karaokeAccent,
                count: playlist.karaokeSongs.length,
              ),
              _buildSongHorizontalList(
                context: context,
                palette: palette,
                playlist: playlist,
                audio: audio,
                songs: playlist.karaokeSongs,
                isKaraoke: true,
              ),
            ],

            // 2. Hindi Melodies Shelf (if 'All' or 'Hindi')
            if ((playlist.selectedLanguage == 'All' || playlist.selectedLanguage == 'Hindi') &&
                playlist.hindiSongs.isNotEmpty) ...[
              _buildShelfHeader(
                palette,
                title: 'Hindi Melodies',
                icon: Icons.music_note_rounded,
                iconColor: Colors.deepOrangeAccent,
                count: playlist.hindiSongs.length,
              ),
              _buildSongHorizontalList(
                context: context,
                palette: palette,
                playlist: playlist,
                audio: audio,
                songs: playlist.hindiSongs,
              ),
            ],

            // 3. Kannada Classics Shelf (if 'All' or 'Kannada')
            if ((playlist.selectedLanguage == 'All' || playlist.selectedLanguage == 'Kannada') &&
                playlist.kannadaSongs.isNotEmpty) ...[
              _buildShelfHeader(
                palette,
                title: 'Kannada Classics',
                icon: Icons.audiotrack_rounded,
                iconColor: Colors.amberAccent,
                count: playlist.kannadaSongs.length,
              ),
              _buildSongHorizontalList(
                context: context,
                palette: palette,
                playlist: playlist,
                audio: audio,
                songs: playlist.kannadaSongs,
              ),
            ],

            // 4. Tamil Hits Shelf (if 'All' or 'Tamil')
            if ((playlist.selectedLanguage == 'All' || playlist.selectedLanguage == 'Tamil') &&
                playlist.tamilSongs.isNotEmpty) ...[
              _buildShelfHeader(
                palette,
                title: 'Tamil Hits',
                icon: Icons.album_rounded,
                iconColor: Colors.cyanAccent,
                count: playlist.tamilSongs.length,
              ),
              _buildSongHorizontalList(
                context: context,
                palette: palette,
                playlist: playlist,
                audio: audio,
                songs: playlist.tamilSongs,
              ),
            ],

            // Section 5: All Songs / Filtered Library Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.library_music_rounded, color: palette.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          playlist.selectedLanguage == 'All'
                              ? 'All Songs Library'
                              : '${playlist.selectedLanguage} Tracks',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: palette.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: palette.surfaceElevated,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: palette.border, width: 0.8),
                      ),
                      child: Text(
                        '${playlist.filteredSongs.length} Tracks',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: palette.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Songs List (Real Playable Items)
            if (playlist.filteredSongs.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 36),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.music_off_rounded, size: 36, color: palette.textMuted),
                        const SizedBox(height: 8),
                        Text(
                          'No songs found matching your selection.',
                          style: TextStyle(color: palette.textMuted, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final song = playlist.filteredSongs[index];
                    return SongTileWidget(
                      song: song,
                      onTap: () {
                        playlist.playSong(song, audio);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const FullPlayerScreen()),
                        );
                      },
                    );
                  },
                  childCount: playlist.filteredSongs.length,
                ),
              ),

            // Bottom space for floating mini player
            const SliverToBoxAdapter(
              child: SizedBox(height: 120),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShelfHeader(
    AppPalette palette, {
    required String title,
    required IconData icon,
    required Color iconColor,
    required int count,
  }) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: palette.textPrimary,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: palette.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: palette.border, width: 0.8),
              ),
              child: Text(
                '$count Songs',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: palette.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSongHorizontalList({
    required BuildContext context,
    required AppPalette palette,
    required PlaylistService playlist,
    required AudioPlayerService audio,
    required List<Song> songs,
    bool isKaraoke = false,
  }) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 160,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: songs.length,
          itemBuilder: (context, index) {
            final song = songs[index];
            return GestureDetector(
              onTap: () {
                if (isKaraoke) {
                  playlist.playSong(song, audio, mode: PlaybackMode.karaoke);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const FullPlayerScreen(startInKaraoke: true),
                    ),
                  );
                } else {
                  playlist.playSong(song, audio, mode: PlaybackMode.normal);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FullPlayerScreen()),
                  );
                }
              },
              child: Container(
                width: 140,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isKaraoke
                        ? palette.karaokeAccent.withAlpha(80)
                        : palette.border,
                    width: 1,
                  ),
                  boxShadow: [
                    if (!palette.isDark)
                      BoxShadow(
                        color: Colors.black.withAlpha(8),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          child: Container(
                            height: 90,
                            width: double.infinity,
                            color: palette.surfaceHover,
                            child: Image.asset(
                              song.coverImage,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                color: palette.surfaceHover,
                                child: Center(
                                  child: Icon(
                                    isKaraoke ? Icons.mic_rounded : Icons.music_note_rounded,
                                    color: palette.primary,
                                    size: 32,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(180),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isKaraoke ? Icons.mic_rounded : Icons.play_arrow_rounded,
                              size: 13,
                              color: isKaraoke ? palette.karaokeAccent : palette.primary,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 6,
                          left: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(180),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              song.language,
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: palette.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            song.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              color: palette.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
