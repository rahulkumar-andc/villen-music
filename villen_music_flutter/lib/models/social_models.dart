class UserProfile {
  final int id;
  final String username;
  final String? email;
  final String bio;
  final String? avatarUrl;
  final bool isPublic;
  final DateTime? createdAt;

  UserProfile({
    required this.id,
    required this.username,
    this.email,
    this.bio = '',
    this.avatarUrl,
    this.isPublic = true,
    this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      username: json['username'] ?? '',
      email: json['email'],
      bio: json['bio'] ?? '',
      avatarUrl: json['avatar_url'],
      isPublic: json['is_public'] ?? true,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }
}

class FollowedArtist {
  final String artistId;
  final String artistName;
  final String? artistImage;

  FollowedArtist({
    required this.artistId,
    required this.artistName,
    this.artistImage,
  });

  factory FollowedArtist.fromJson(Map<String, dynamic> json) {
    return FollowedArtist(
      artistId: json['artist_id'],
      artistName: json['artist_name'],
      artistImage: json['artist_image'],
    );
  }
}

class PlaylistSong {
  final String songId;
  final String title;
  final String artist;
  final String? image;
  final int duration;
  final String? addedByUsername;

  PlaylistSong({
    required this.songId,
    required this.title,
    required this.artist,
    this.image,
    this.duration = 0,
    this.addedByUsername,
  });

  factory PlaylistSong.fromJson(Map<String, dynamic> json) {
    return PlaylistSong(
      songId: json['song_id'],
      title: json['title'],
      artist: json['artist'],
      image: json['image'],
      duration: json['duration'] ?? 0,
      addedByUsername: json['added_by_username'],
    );
  }
}

class Playlist {
  final int id;
  final String owner;
  final String name;
  final String description;
  final bool isPublic;
  final String? image;
  final List<PlaylistSong> songs;
  final int collaboratorsCount;
  final bool isOwner;
  final bool isCollaborator;

  Playlist({
    required this.id,
    required this.owner,
    required this.name,
    this.description = '',
    this.isPublic = true,
    this.image,
    this.songs = const [],
    this.collaboratorsCount = 0,
    this.isOwner = false,
    this.isCollaborator = false,
  });

  factory Playlist.fromJson(Map<String, dynamic> json) {
    var songsList = json['songs'] as List? ?? [];
    List<PlaylistSong> songs = songsList.map((i) => PlaylistSong.fromJson(i)).toList();

    return Playlist(
      id: json['id'],
      owner: json['owner'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      isPublic: json['is_public'] ?? true,
      image: json['image'],
      songs: songs,
      collaboratorsCount: json['collaborators_count'] ?? 0,
      isOwner: json['is_owner'] ?? false,
      isCollaborator: json['is_collaborator'] ?? false,
    );
  }
}

class Activity {
  final int id;
  final String username;
  final String? userAvatar;
  final String actionType;
  final String targetId;
  final String description;
  final DateTime createdAt;

  Activity({
    required this.id,
    required this.username,
    this.userAvatar,
    required this.actionType,
    required this.targetId,
    required this.description,
    required this.createdAt,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'],
      username: json['username'] ?? '',
      userAvatar: json['user_avatar'],
      actionType: json['action_type'] ?? '',
      targetId: json['target_id'] ?? '',
      description: json['description'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
