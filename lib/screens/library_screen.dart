import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/audio_player_service.dart';
import '../services/playlist_service.dart';
import '../services/playlist_api_service.dart';
import '../services/auth_service.dart';
import '../models/song_model.dart';
import '../models/playlist_model.dart';
import '../theme/app_colors.dart';
import '../widgets/song_tile_widget.dart';
import 'player/full_player_screen.dart';
import 'player/karaoke_player_screen.dart';
import 'playlist_detail_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthService>();
      context.read<PlaylistApiService>().fetchPlaylists(token: auth.token);
    });
  }

  void _showCreatePlaylistDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border),
        ),
        title: const Row(
          children: [
            Icon(Icons.playlist_add, color: AppColors.primary),
            SizedBox(width: 10),
            Text('Create Playlist', style: TextStyle(color: AppColors.textPrimary)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              autofocus: true,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Playlist Name',
                labelStyle: const TextStyle(color: AppColors.textSecondary),
                hintText: 'e.g. My Favorite Telugu Hits',
                hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                filled: true,
                fillColor: AppColors.surfaceLight,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              maxLines: 2,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Description (Optional)',
                labelStyle: const TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.surfaceLight,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
            ),
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(ctx);

              final auth = context.read<AuthService>();
              final api = context.read<PlaylistApiService>();

              final created = await api.createPlaylist(
                name,
                description: descCtrl.text.trim(),
                token: auth.token,
              );

              if (created != null && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Created playlist "${created.name}"'),
                    backgroundColor: AppColors.primary,
                  ),
                );
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(PlaylistModel pl) {
    final nameCtrl = TextEditingController(text: pl.name);
    final descCtrl = TextEditingController(text: pl.description);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border),
        ),
        title: const Text('Rename Playlist', style: TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              autofocus: true,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Playlist Name',
                labelStyle: const TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.surfaceLight,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              maxLines: 2,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Description',
                labelStyle: const TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.surfaceLight,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
            ),
            onPressed: () async {
              final newName = nameCtrl.text.trim();
              if (newName.isEmpty) return;
              Navigator.pop(ctx);

              final auth = context.read<AuthService>();
              final api = context.read<PlaylistApiService>();
              final ok = await api.renamePlaylist(
                pl.id,
                newName,
                newDescription: descCtrl.text.trim(),
                token: auth.token,
              );

              if (ok && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Playlist updated successfully')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(PlaylistModel pl) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border),
        ),
        title: const Text('Delete Playlist', style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          'Are you sure you want to delete "${pl.name}"? Songs will remain in catalogue.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final auth = context.read<AuthService>();
              final api = context.read<PlaylistApiService>();
              final ok = await api.deletePlaylist(pl.id, token: auth.token);

              if (ok && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Playlist deleted')),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final playlist = context.watch<PlaylistService>();
    final audio = context.watch<AudioPlayerService>();
    final playlistApi = context.watch<PlaylistApiService>();
    final auth = context.watch<AuthService>();

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Your Music Library'),
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: [
              Tab(text: '📁 Playlists'),
              Tab(text: 'All Songs'),
              Tab(text: '🎤 Karaoke'),
              Tab(text: '❤️ Favorites'),
              Tab(text: '🕒 Recent'),
            ],
          ),
        ),
        body: SafeArea(
          child: TabBarView(
            children: [
              // 1. Playlists Tab (New)
              _buildPlaylistsTab(playlistApi, auth),

              // 2. All Songs Tab
              _buildSongList(
                playlist.allSongs,
                audio,
                playlist,
                'No songs found in catalog',
              ),

              // 3. Karaoke Only Tab
              _buildSongList(
                playlist.karaokeSongs,
                audio,
                playlist,
                'No karaoke tracks available',
                defaultMode: PlaybackMode.karaoke,
              ),

              // 4. Favorites Tab
              _buildSongList(
                playlist.favoriteSongs,
                audio,
                playlist,
                'No favorites added yet. Tap the heart icon on any song!',
              ),

              // 5. Recently Played Tab
              _buildSongList(
                playlist.recentlyPlayed,
                audio,
                playlist,
                'No songs played yet. Pick any song to start jamming!',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaylistsTab(PlaylistApiService playlistApi, AuthService auth) {
    final playlists = playlistApi.playlists;

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      onRefresh: () async {
        await playlistApi.fetchPlaylists(token: auth.token);
      },
      child: CustomScrollView(
        slivers: [
          // Top Action Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Custom Playlists',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        auth.isAuthenticated
                            ? 'Synced with MongoDB Atlas'
                            : 'Guest mode • Local playlists',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('New Playlist', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: _showCreatePlaylistDialog,
                  ),
                ],
              ),
            ),
          ),

          // Loading state
          if (playlistApi.isLoading && playlists.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          // Empty State
          else if (playlists.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                          color: AppColors.surfaceLight,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.queue_music, size: 48, color: AppColors.primary),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No custom playlists yet',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Create playlists to organize your favorite tracks for quick dual-mode playback and karaoke sessions.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.add),
                        label: const Text('Create First Playlist', style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: _showCreatePlaylistDialog,
                      ),
                    ],
                  ),
                ),
              ),
            )
          // Playlists List
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final pl = playlists[index];
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withAlpha(200),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      leading: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: AppColors.purplePinkGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.queue_music, color: Colors.white, size: 28),
                      ),
                      title: Text(
                        pl.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (pl.description.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              pl.description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            ),
                          ],
                          const SizedBox(height: 4),
                          Text(
                            '${pl.songCount} track${pl.songCount == 1 ? '' : 's'}',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      trailing: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: AppColors.textMuted),
                        color: AppColors.surfaceLight,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: AppColors.border),
                        ),
                        onSelected: (value) {
                          if (value == 'rename') {
                            _showRenameDialog(pl);
                          } else if (value == 'delete') {
                            _showDeleteDialog(pl);
                          }
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(
                            value: 'rename',
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                                SizedBox(width: 8),
                                Text('Rename', style: TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline, size: 18, color: AppColors.accent),
                                SizedBox(width: 8),
                                Text('Delete', style: TextStyle(color: AppColors.accent, fontSize: 13)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PlaylistDetailScreen(playlist: pl),
                          ),
                        );
                      },
                    ),
                  ),
                );
                },
                childCount: playlists.length,
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  Widget _buildSongList(
    List<Song> songs,
    AudioPlayerService audio,
    PlaylistService playlist,
    String emptyMessage, {
    PlaybackMode defaultMode = PlaybackMode.normal,
  }) {
    if (songs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.library_music_outlined, size: 48, color: AppColors.textMuted),
              const SizedBox(height: 12),
              Text(
                emptyMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 120),
      itemCount: songs.length,
      itemBuilder: (context, index) {
        final song = songs[index];
        return SongTileWidget(
          song: song,
          onTap: () {
            playlist.playSong(song, audio, mode: defaultMode);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => defaultMode == PlaybackMode.karaoke
                    ? const KaraokePlayerScreen()
                    : const FullPlayerScreen(),
              ),
            );
          },
        );
      },
    );
  }
}
