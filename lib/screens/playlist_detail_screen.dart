import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/playlist_model.dart';
import '../models/song_model.dart';
import '../data/song_catalog.dart';
import '../services/audio_player_service.dart';
import '../services/playlist_service.dart';
import '../services/playlist_api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../widgets/song_tile_widget.dart';
import 'player/full_player_screen.dart';
import 'player/karaoke_player_screen.dart';

class PlaylistDetailScreen extends StatefulWidget {
  final PlaylistModel playlist;

  const PlaylistDetailScreen({super.key, required this.playlist});

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  late PlaylistModel _currentPlaylist;

  @override
  void initState() {
    super.initState();
    _currentPlaylist = widget.playlist;
  }

  void _showRenameDialog() {
    final nameCtrl = TextEditingController(text: _currentPlaylist.name);
    final descCtrl = TextEditingController(text: _currentPlaylist.description);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border),
        ),
        title: const Text('Edit Playlist', style: TextStyle(color: AppColors.textPrimary)),
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
              final newName = nameCtrl.text.trim();
              if (newName.isEmpty) return;
              Navigator.pop(ctx);

              final auth = context.read<AuthService>();
              final api = context.read<PlaylistApiService>();

              final ok = await api.renamePlaylist(
                _currentPlaylist.id,
                newName,
                newDescription: descCtrl.text.trim(),
                token: auth.token,
              );

              if (ok && mounted) {
                setState(() {
                  _currentPlaylist = _currentPlaylist.copyWith(
                    name: newName,
                    description: descCtrl.text.trim(),
                  );
                });
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

  void _showDeleteDialog() {
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
          'Are you sure you want to delete "${_currentPlaylist.name}"? This action cannot be undone.',
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

              final ok = await api.deletePlaylist(_currentPlaylist.id, token: auth.token);
              if (ok && mounted) {
                Navigator.pop(context);
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

  void _showAddSongsBottomSheet() {
    final availableSongs = SongCatalog.allSongs
        .where((s) => !_currentPlaylist.songIds.contains(s.id))
        .toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Container(
            height: MediaQuery.of(context).size.height * 0.7,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Add Songs to Playlist',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppColors.textMuted),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                const Divider(color: AppColors.border),
                if (availableSongs.isEmpty)
                  const Expanded(
                    child: Center(
                      child: Text(
                        'All available catalogue tracks are already in this playlist.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      itemCount: availableSongs.length,
                      itemBuilder: (context, index) {
                        final song = availableSongs[index];
                        return ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              song.coverImage,
                              width: 44,
                              height: 44,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                width: 44,
                                height: 44,
                                color: AppColors.surfaceLight,
                                child: const Icon(Icons.music_note, color: AppColors.primary),
                              ),
                            ),
                          ),
                          title: Text(
                            song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            '${song.artist} • ${song.language}',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                            onPressed: () async {
                              final auth = context.read<AuthService>();
                              final api = context.read<PlaylistApiService>();
                              final messenger = ScaffoldMessenger.of(context);

                              final ok = await api.addSongToPlaylist(
                                _currentPlaylist.id,
                                song.id,
                                token: auth.token,
                              );

                              if (!ok) return;

                              if (ctx.mounted) {
                                Navigator.pop(ctx);
                              }

                              if (!mounted) return;

                              setState(() {
                                _currentPlaylist = _currentPlaylist.copyWith(
                                  songIds: List<String>.from(_currentPlaylist.songIds)..add(song.id),
                                );
                              });

                              messenger.showSnackBar(
                                SnackBar(content: Text('Added "${song.title}" to playlist')),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final playlistApi = context.watch<PlaylistApiService>();
    // Synchronize latest playlist data from Provider if available
    final fresh = playlistApi.playlists.firstWhere(
      (p) => p.id == _currentPlaylist.id,
      orElse: () => _currentPlaylist,
    );
    _currentPlaylist = fresh;

    final audio = context.watch<AudioPlayerService>();
    final playlistService = context.watch<PlaylistService>();

    // Resolve song models from catalog
    final resolvedSongs = <Song>[];
    for (final songId in _currentPlaylist.songIds) {
      try {
        final match = SongCatalog.allSongs.firstWhere((s) => s.id == songId);
        resolvedSongs.add(match);
      } catch (_) {}
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_currentPlaylist.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Rename / Edit',
            onPressed: _showRenameDialog,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.accent),
            tooltip: 'Delete Playlist',
            onPressed: _showDeleteDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header Banner
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withAlpha(40),
                      AppColors.surfaceLight,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary.withAlpha(60)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            gradient: AppColors.purplePinkGradient,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.queue_music, color: Colors.white, size: 36),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _currentPlaylist.name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              if (_currentPlaylist.description.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  _currentPlaylist.description,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 6),
                              Text(
                                '${resolvedSongs.length} track${resolvedSongs.length == 1 ? '' : 's'} • Saved in VibeTune',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    // Playback Buttons Row
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Play Normal', style: TextStyle(fontWeight: FontWeight.bold)),
                            onPressed: resolvedSongs.isEmpty
                                ? null
                                : () {
                                    playlistService.playSong(resolvedSongs.first, audio, mode: PlaybackMode.normal);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const FullPlayerScreen()),
                                    );
                                  },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.karaokeAccent,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.mic, size: 18),
                            label: const Text('Play Karaoke', style: TextStyle(fontWeight: FontWeight.bold)),
                            onPressed: resolvedSongs.isEmpty
                                ? null
                                : () {
                                    playlistService.playSong(resolvedSongs.first, audio, mode: PlaybackMode.karaoke);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const KaraokePlayerScreen()),
                                    );
                                  },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Add Song Shortcut
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Playlist Tracks',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.add, size: 18, color: AppColors.primary),
                      label: const Text('Add Song', style: TextStyle(color: AppColors.primary)),
                      onPressed: _showAddSongsBottomSheet,
                    ),
                  ],
                ),
              ),
            ),

            // Track List or Empty State
            if (resolvedSongs.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.music_off_outlined, size: 52, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        const Text(
                          'No songs in this playlist yet.',
                          style: TextStyle(fontSize: 16, color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Tap "Add Song" above or use "Add to Playlist" on any catalogue song!',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.surfaceLight,
                            foregroundColor: AppColors.primary,
                          ),
                          icon: const Icon(Icons.add),
                          label: const Text('Browse Catalogue to Add'),
                          onPressed: _showAddSongsBottomSheet,
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
                    final song = resolvedSongs[index];
                    return Dismissible(
                      key: Key('pl_song_${song.id}'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: AppColors.accent,
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) async {
                        final auth = context.read<AuthService>();
                        final api = context.read<PlaylistApiService>();
                        await api.removeSongFromPlaylist(_currentPlaylist.id, song.id, token: auth.token);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Removed "${song.title}" from playlist')),
                        );
                      },
                      child: SongTileWidget(song: song),
                    );
                  },
                  childCount: resolvedSongs.length,
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}

