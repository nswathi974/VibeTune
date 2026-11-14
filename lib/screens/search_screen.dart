import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/audio_player_service.dart';
import '../services/playlist_service.dart';
import '../theme/app_colors.dart';
import '../widgets/song_tile_widget.dart';
import 'player/full_player_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _karaokeOnly = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playlist = context.watch<PlaylistService>();
    final audio = context.watch<AudioPlayerService>();

    final results = playlist.filteredSongs.where((song) {
      if (_karaokeOnly && !song.isKaraokeAvailable) return false;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Search & Explore'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Input Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  onChanged: (query) {
                    playlist.setSearchQuery(query);
                  },
                  decoration: InputDecoration(
                    hintText: 'Search songs, singers, movies...',
                    hintStyle: const TextStyle(color: AppColors.textMuted),
                    prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: AppColors.textMuted),
                            onPressed: () {
                              _searchController.clear();
                              playlist.setSearchQuery('');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),

            // Quick Filter Chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  FilterChip(
                    label: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.mic, size: 14, color: AppColors.karaokeAccent),
                        SizedBox(width: 4),
                        Text('Karaoke Only'),
                      ],
                    ),
                    selected: _karaokeOnly,
                    selectedColor: AppColors.karaokeAccent.withAlpha(50),
                    backgroundColor: AppColors.surface,
                    checkmarkColor: AppColors.karaokeAccent,
                    labelStyle: TextStyle(
                      fontSize: 11,
                      color: _karaokeOnly ? AppColors.karaokeAccent : AppColors.textSecondary,
                      fontWeight: _karaokeOnly ? FontWeight.bold : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: _karaokeOnly ? AppColors.karaokeAccent : AppColors.border,
                      ),
                    ),
                    onSelected: (selected) {
                      setState(() => _karaokeOnly = selected);
                    },
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${results.length} results',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // Results List
            Expanded(
              child: results.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.music_off, size: 56, color: AppColors.textMuted.withAlpha(120)),
                          const SizedBox(height: 12),
                          const Text(
                            'No songs found',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Try searching for Arijit, Belageddu, Sid Sriram, or Premam',
                            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: results.length,
                      padding: const EdgeInsets.only(bottom: 120),
                      itemBuilder: (context, index) {
                        final song = results[index];
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
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
