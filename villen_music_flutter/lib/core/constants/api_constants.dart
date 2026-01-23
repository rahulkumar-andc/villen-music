/// API Constants for VILLEN Music App
/// 
/// Contains base URLs and endpoint definitions for the Django backend.
library;

class ApiConstants {
  // Base URL for the Django backend
  static const String baseUrl = 'https://villen-music.onrender.com/api';
  
  // Authentication endpoints
  static const String login = '/auth/login/';
  static const String register = '/auth/register/';
  static const String refreshToken = '/auth/refresh/';
  
  // Song endpoints
  static const String search = '/search/';
  static const String trending = '/trending/';
  static String stream(String songId) => '/stream/$songId/';
  static String songDetails(String songId) => '/song/$songId/';
  static String songLyrics(String songId) => '/song/$songId/lyrics/';
  static String songRelated(String songId) => '/song/$songId/related/';
  
  // Album & Artist endpoints
  static String albumDetails(String albumId) => '/album/$albumId/';
  static String artistDetails(String artistId) => '/artist/$artistId/';
  
  // User endpoints (require authentication)
  static const String userLikes = '/user/likes/';
  
  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
