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

    final featuredSong = SongCatalog.allSongs.first;
    final userName = auth.currentUser?.name ?? 'Guest Explorer';

    // YouTube verified tracks for streaming shelf
    final youtubeTracks = playlist.allSongs.where((s) => s.isYouTubeTrack).toList();

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

            // Shelf 1: Karaoke Ready Tracks Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.mic_external_on_rounded, color: palette.karaokeAccent, size: 20),
                        const SizedBox(width: 6),
                        Text(
                          'Karaoke Ready Tracks',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: palette.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${playlist.karaokeSongs.length} Songs',
                      style: TextStyle(fontSize: 12, color: palette.textMuted),
                    ),
                  ],
                ),
              ),
            ),

            // Shelf 1: Horizontal Karaoke Cards
            SliverToBoxAdapter(
              child: SizedBox(
                height: 155,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: playlist.karaokeSongs.take(8).length,
                  itemBuilder: (context, index) {
                    final song = playlist.karaokeSongs[index];
                    return GestureDetector(
                      onTap: () {
                        playlist.playSong(song, audio, mode: PlaybackMode.karaoke);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const FullPlayerScreen(startInKaraoke: true),
                          ),
                        );
                      },
                      child: Container(
                        width: 135,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: palette.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: palette.border,
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
                                    height: 88,
                                    width: double.infinity,
                                    color: palette.surfaceHover,
                                    child: Image.asset(song.coverImage, fit: BoxFit.cover),
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
                                      Icons.mic_rounded,
                                      size: 13,
                                      color: palette.karaokeAccent,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
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
                                    song.language,
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
            ),

            // Shelf 2: Trending Commercial Hits (YouTube Verified Streams)
            if (youtubeTracks.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.play_circle_fill_rounded, color: Colors.redAccent, size: 20),
                          const SizedBox(width: 6),
                          Text(
                            'Official YouTube Streams',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: palette.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${youtubeTracks.length} Tracks',
                        style: TextStyle(fontSize: 12, color: palette.textMuted),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 155,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: youtubeTracks.length,
                    itemBuilder: (context, index) {
                      final song = youtubeTracks[index];
                      return GestureDetector(
                        onTap: () {
                          playlist.playSong(song, audio);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const FullPlayerScreen()),
                          );
                        },
                        child: Container(
                          width: 135,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: palette.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: palette.border,
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
                                      height: 88,
                                      width: double.infinity,
                                      color: palette.surfaceHover,
                                      child: Image.asset(song.coverImage, fit: BoxFit.cover),
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
                                      child: const Icon(
                                        Icons.smart_display_rounded,
                                        size: 13,
                                        color: Colors.redAccent,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
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
                                      song.language,
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
              ),
            ],

            // Section 3: Indian Music Library Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.library_music_rounded, color: palette.primary, size: 20),
                        const SizedBox(width: 6),
                        Text(
                          playlist.selectedLanguage == 'All'
                              ? 'Indian Music Library'
                              : '${playlist.selectedLanguage} Hits',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: palette.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${playlist.filteredSongs.length} Tracks',
                      style: TextStyle(fontSize: 12, color: palette.textMuted),
                    ),
                  ],
                ),
              ),
            ),

            // Songs List (Real Playable Items)
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
}
