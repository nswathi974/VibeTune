class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final List<String> preferredLanguages;
  final List<String> favoriteSongIds;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.role = 'user',
    this.preferredLanguages = const ['Hindi', 'Kannada', 'Telugu', 'Tamil', 'Malayalam'],
    this.favoriteSongIds = const [],
  });

  bool get isAdmin => role == 'admin';

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    List<String>? preferredLanguages,
    List<String>? favoriteSongIds,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      preferredLanguages: preferredLanguages ?? this.preferredLanguages,
      favoriteSongIds: favoriteSongIds ?? this.favoriteSongIds,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        'preferredLanguages': preferredLanguages,
        'favoriteSongIds': favoriteSongIds,
      };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String? ?? json['_id'] as String? ?? 'user_1',
        name: json['name'] as String? ?? 'Music Enthusiast',
        email: json['email'] as String? ?? 'user@vibetune.com',
        role: json['role'] as String? ?? 'user',
        preferredLanguages: (json['preferredLanguages'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const ['Hindi', 'Kannada', 'Telugu', 'Tamil', 'Malayalam'],
        favoriteSongIds: (json['favoriteSongIds'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
      );
}
