import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/playlist_service.dart';
import '../theme/app_colors.dart';
import 'welcome_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _audioQuality = '320kbps (Lossless High-Res)';
  bool _normalizeVolume = true;
  bool _hardwareAcceleration = true;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final playlist = context.watch<PlaylistService>();
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profile & Settings'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          children: [
            // User Header Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 2),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Icon(Icons.person, size: 36, color: AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'Swathi',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.email ?? 'swathi@vibetune.com',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: (user?.isAdmin ?? false)
                                    ? AppColors.karaokeAccent.withAlpha(40)
                                    : AppColors.secondary.withAlpha(40),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: (user?.isAdmin ?? false)
                                      ? AppColors.karaokeAccent
                                      : AppColors.secondary.withAlpha(90),
                                ),
                              ),
                              child: Text(
                                (user?.isAdmin ?? false) ? 'ADMIN' : 'USER',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: (user?.isAdmin ?? false)
                                      ? AppColors.karaokeAccent
                                      : AppColors.secondary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withAlpha(40),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppColors.primary.withAlpha(90)),
                              ),
                              child: const Text(
                                'MCA Project',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // How To Add Songs Guide Card (Crucial for User Requirement!)
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF182234), Color(0xFF101622)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary.withAlpha(120), width: 1.2),
              ),
              child: ExpansionTile(
                initiallyExpanded: true,
                tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                leading: const Icon(Icons.help_outline, color: AppColors.primary, size: 24),
                title: const Text(
                  'How to Add Your Own Songs',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                subtitle: const Text(
                  'Step-by-step guide for audio assets & catalog',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
                childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                children: [
                  _guideStep(
                    stepNumber: '1',
                    title: 'Place Vocal Audio Track',
                    desc: 'Copy your normal/vocal song file (.mp3 or .wav) into:\nassets/audio/normal/<your_song_name>.mp3',
                  ),
                  const SizedBox(height: 10),
                  _guideStep(
                    stepNumber: '2',
                    title: 'Place Karaoke Audio Track',
                    desc: 'Copy your instrumental/backing song file into:\nassets/audio/karaoke/<your_song_name>.mp3',
                  ),
                  const SizedBox(height: 10),
                  _guideStep(
                    stepNumber: '3',
                    title: 'Place Timed Lyrics (.lrc)',
                    desc: 'Copy your synchronized timestamped lyrics file into:\nassets/lyrics/<your_song_name>.lrc',
                  ),
                  const SizedBox(height: 10),
                  _guideStep(
                    stepNumber: '4',
                    title: 'Register in Song Catalog',
                    desc: 'Open "lib/data/song_catalog.dart" and add a new Song(title, artist, language, paths...) entry.',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Audio Playback Quality Settings
            const Text(
              'Audio Settings',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 10),

            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  ListTile(
                    title: const Text('Audio Output Quality', style: TextStyle(fontSize: 14)),
                    subtitle: Text(_audioQuality, style: const TextStyle(fontSize: 12, color: AppColors.primary)),
                    trailing: PopupMenuButton<String>(
                      icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                      onSelected: (val) => setState(() => _audioQuality = val),
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: '320kbps (Lossless High-Res)', child: Text('320kbps (High-Res)')),
                        const PopupMenuItem(value: '192kbps (Standard Hi-Fi)', child: Text('192kbps (Standard)')),
                        const PopupMenuItem(value: '128kbps (Data Saver)', child: Text('128kbps (Saver)')),
                      ],
                    ),
                  ),
                  const Divider(color: AppColors.border, height: 1),
                  SwitchListTile(
                    activeThumbColor: AppColors.primary,
                    title: const Text('Seamless Mode Transition', style: TextStyle(fontSize: 14)),
                    subtitle: const Text('Preserves exact timestamp when switching Vocal <-> Karaoke', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    value: _normalizeVolume,
                    onChanged: (val) => setState(() => _normalizeVolume = val),
                  ),
                  const Divider(color: AppColors.border, height: 1),
                  SwitchListTile(
                    activeThumbColor: AppColors.primary,
                    title: const Text('Hardware Audio Acceleration', style: TextStyle(fontSize: 14)),
                    subtitle: const Text('Optimized playback for Android Pixel 8 emulator', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    value: _hardwareAcceleration,
                    onChanged: (val) => setState(() => _hardwareAcceleration = val),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Project Credits Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('About VibeTune', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  const Text('Platform: Flutter & Dart on Android Pixel 8\nVersion: 1.0.0 (Release Candidate)\nFocus: Dual-Mode Music & Synchronized Karaoke Player\nCatalog: 50+ Multi-Language Indian Songs', style: TextStyle(fontSize: 12, height: 1.5, color: AppColors.textSecondary)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.favorite, size: 14, color: AppColors.accent),
                      const SizedBox(width: 6),
                      Text('Favorites in Library: ${playlist.favoriteSongs.length} songs', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Sign Out / Switch User Button
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                side: const BorderSide(color: AppColors.error, width: 1.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.logout, size: 18, color: AppColors.error),
              label: const Text('Sign Out / Switch Profile', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
              onPressed: () async {
                final navigator = Navigator.of(context);
                await auth.signOut();
                if (!mounted) return;
                navigator.pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                  (route) => false,
                );
              },
            ),

            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  Widget _guideStep({required String stepNumber, required String title, required String desc}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              stepNumber,
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 2),
              Text(desc, style: const TextStyle(fontSize: 11, height: 1.4, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }
}
