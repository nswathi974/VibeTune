import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song_model.dart';
import '../services/playlist_api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';

class AddToPlaylistDialog {
  static void show(BuildContext context, Song song) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _AddToPlaylistSheet(song: song),
    );
  }
}

class _AddToPlaylistSheet extends StatefulWidget {
  final Song song;

  const _AddToPlaylistSheet({required this.song});

  @override
  State<_AddToPlaylistSheet> createState() => _AddToPlaylistSheetState();
}

class _AddToPlaylistSheetState extends State<_AddToPlaylistSheet> {
  bool _isCreating = false;
  final TextEditingController _newPlaylistNameCtrl = TextEditingController();

  @override
  void dispose() {
    _newPlaylistNameCtrl.dispose();
    super.dispose();
  }

  void _showCreateInline() {
    setState(() {
      _isCreating = true;
    });
  }

  Future<void> _handleCreatePlaylist() async {
    final name = _newPlaylistNameCtrl.text.trim();
    if (name.isEmpty) return;

    final auth = context.read<AuthService>();
    final api = context.read<PlaylistApiService>();

    final created = await api.createPlaylist(
      name,
      token: auth.token,
      initialSongs: [widget.song.id],
    );

    if (created != null && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Created "$name" and added "${widget.song.title}"'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final playlistApi = context.watch<PlaylistApiService>();
    final auth = context.watch<AuthService>();
    final playlists = playlistApi.playlists;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.65,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Add to Playlist',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textMuted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(color: AppColors.border),

            // Inline Create Playlist Field or Button
            if (_isCreating) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primary.withAlpha(120)),
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _newPlaylistNameCtrl,
                      autofocus: true,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        hintText: 'Enter playlist title...',
                        hintStyle: TextStyle(color: AppColors.textMuted),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => setState(() => _isCreating = false),
                          child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: _handleCreatePlaylist,
                          child: const Text('Create & Add'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ] else ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(30),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primary.withAlpha(80)),
                  ),
                  child: const Icon(Icons.add, color: AppColors.primary),
                ),
                title: const Text(
                  'New Playlist',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: _showCreateInline,
              ),
              const Divider(color: AppColors.border),
            ],

            // Existing Playlists List
            if (playlists.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'No custom playlists yet. Tap "New Playlist" above to create your first one!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: playlists.length,
                  itemBuilder: (context, index) {
                    final pl = playlists[index];
                    final containsSong = pl.songIds.contains(widget.song.id);

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.queue_music, color: AppColors.textSecondary),
                      ),
                      title: Text(
                        pl.name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        '${pl.songCount} track${pl.songCount == 1 ? '' : 's'}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                      trailing: containsSong
                          ? const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle, color: AppColors.primary, size: 20),
                                SizedBox(width: 4),
                                Text(
                                  'Added',
                                  style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ],
                            )
                          : const Icon(Icons.add_circle_outline, color: AppColors.textMuted),
                      onTap: containsSong
                          ? null
                          : () async {
                              final ok = await playlistApi.addSongToPlaylist(
                                pl.id,
                                widget.song.id,
                                token: auth.token,
                              );
                              if (ok && context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Added "${widget.song.title}" to ${pl.name}'),
                                    backgroundColor: AppColors.primary,
                                  ),
                                );
                              }
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

