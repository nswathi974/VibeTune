import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/audio_player_service.dart';
import '../services/playlist_service.dart';
import '../theme/app_colors.dart';
import '../widgets/mini_player_widget.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'library_screen.dart';
import 'profile_screen.dart';
import 'player/karaoke_player_screen.dart';

class MainNavigationScaffold extends StatefulWidget {
  const MainNavigationScaffold({super.key});

  @override
  State<MainNavigationScaffold> createState() => _MainNavigationScaffoldState();
}

class _MainNavigationScaffoldState extends State<MainNavigationScaffold> {
  int _currentIndex = 0;

  List<Widget> _buildScreens() => [
    const HomeScreen(),
    const SearchScreen(),
    KaraokePlayerScreen(isEmbedded: true, isActiveTab: _currentIndex == 2),
    const LibraryScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final audio = context.read<AudioPlayerService>();
      final playlist = context.read<PlaylistService>();

      audio.onNextRequested = () => playlist.nextSong(audio);
      audio.onPreviousRequested = () => playlist.previousSong(audio);
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final audio = context.watch<AudioPlayerService>();
    final hasActiveSong = audio.currentSong != null;

    return Scaffold(
      backgroundColor: palette.background,
      body: IndexedStack(
        index: _currentIndex,
        children: _buildScreens(),
      ),
      bottomNavigationBar: Container(
        color: palette.background,
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Floating Frosted Mini Player (hidden when on full Karaoke stage tab)
              if (hasActiveSong && _currentIndex != 2) const MiniPlayerWidget(),

              // Frosted Bottom Navigation Bar
              ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: palette.isDark
                          ? palette.surface.withAlpha(220)
                          : palette.surface.withAlpha(240),
                      border: Border(
                        top: BorderSide(
                          color: palette.isDark
                              ? Colors.white.withAlpha(15)
                              : Colors.black.withAlpha(15),
                          width: 0.8,
                        ),
                      ),
                    ),
                    child: BottomNavigationBar(
                      currentIndex: _currentIndex,
                      type: BottomNavigationBarType.fixed,
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      selectedItemColor: _currentIndex == 2
                          ? palette.karaokeAccent
                          : palette.primary,
                      unselectedItemColor: palette.textMuted,
                      selectedLabelStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                      onTap: (idx) => setState(() => _currentIndex = idx),
                      items: [
                        const BottomNavigationBarItem(
                          icon: Icon(Icons.home_outlined),
                          activeIcon: Icon(Icons.home_rounded),
                          label: 'Home',
                        ),
                        const BottomNavigationBarItem(
                          icon: Icon(Icons.search_rounded),
                          activeIcon: Icon(Icons.search_rounded),
                          label: 'Search',
                        ),
                        BottomNavigationBarItem(
                          icon: const Icon(Icons.mic_none_rounded),
                          activeIcon: Icon(Icons.mic_rounded, color: palette.karaokeAccent),
                          label: 'Karaoke',
                        ),
                        const BottomNavigationBarItem(
                          icon: Icon(Icons.library_music_outlined),
                          activeIcon: Icon(Icons.library_music_rounded),
                          label: 'Library',
                        ),
                        const BottomNavigationBarItem(
                          icon: Icon(Icons.person_outline_rounded),
                          activeIcon: Icon(Icons.person_rounded),
                          label: 'Profile',
                        ),
                      ],
                    ),
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
