/// Song Model
/// 
/// Represents a song/track in the VILLEN Music app.
/// Matches the JSON response from the Django backend.
library;

class Song {
  final String id;
  final String title;
  final String artist;
  final String? album;
  final String? albumId;
  final String? image;
  final List<dynamic>? images;
  final dynamic duration; // Can be int or String from API
  final String? year;
  final String? language;
  final bool hasLyrics;
  final String? url; // Perma URL
  final bool isExplicit;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    this.album,
    this.albumId,
    this.image,
    this.images,
    this.duration,
    this.year,
    this.language,
    this.hasLyrics = false,
    this.url,
    this.isExplicit = false,
  });

  /// Factory constructor to create a Song from JSON
  factory Song.fromJson(Map<String, dynamic> json) {
    // Helper to safely get string
    String? getString(String key) {
      final val = json[key];
      return val?.toString();
    }

    return Song(
      id: getString('id') ?? '',
      title: getString('title') ?? 'Unknown Title',
      artist: getString('artist') ?? 'Unknown Artist',
      album: getString('album'),
      albumId: getString('album_id'),
      image: getString('image'),
      images: json['images'] as List<dynamic>?,
      duration: json['duration'], // Keep as dynamic, handle formatting in UI/Utils
      year: getString('year'),
      language: getString('language'),
      hasLyrics: json['has_lyrics'] == true,
      url: getString('url'),
      isExplicit: json['explicit'] == true,
    );
  }

  /// Convert Song to JSON (for local storage/caching)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'album_id': albumId,
      'image': image,
      'images': images,
      'duration': duration,
      'year': year,
      'language': language,
      'has_lyrics': hasLyrics,
      'url': url,
      'explicit': isExplicit,
    };
  }

  int get durationInSeconds {
    if (duration == null) return 0;
    if (duration is int) return duration as int;
    if (duration is String) return int.tryParse(duration as String) ?? 0;
    return 0;
  }

  @override
  String toString() => 'Song(title: $title, artist: $artist)';
  
  // Equatable support for value comparison
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Song && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
