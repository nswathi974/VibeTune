class PlaylistModel {
  final String id;
  final String name;
  final String description;
  final List<String> songIds;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PlaylistModel({
    required this.id,
    required this.name,
    this.description = '',
    this.songIds = const [],
    this.createdAt,
    this.updatedAt,
  });

  int get songCount => songIds.length;

  PlaylistModel copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? songIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PlaylistModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      songIds: songIds ?? this.songIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'songs': songIds,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory PlaylistModel.fromJson(Map<String, dynamic> json) {
    List<String> parsedSongs = [];
    if (json['songs'] is List) {
      parsedSongs = (json['songs'] as List)
          .map((item) => item is String ? item : item['id']?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
    }

    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return PlaylistModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name'] as String? ?? 'Untitled Playlist',
      description: json['description'] as String? ?? '',
      songIds: parsedSongs,
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }
}

