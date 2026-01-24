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
  
  // FIX #10: Timeouts - Stream endpoints need shorter timeout (15s max network latency)
  // General API endpoints use standard timeout (30s for processing)
  static const Duration streamTimeout = Duration(seconds: 15);  // For stream proxying
  static const Duration connectTimeout = Duration(seconds: 30); // For general API
  static const Duration receiveTimeout = Duration(seconds: 30); // For general API
}