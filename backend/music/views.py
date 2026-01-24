# backend/music/views.py

import logging
import requests
from django.http import StreamingHttpResponse
from django.http import JsonResponse
from django.views.decorators.http import require_GET
from django.views.decorators.cache import cache_page

from .services.jiosaavn_service import JioSaavnService

logger = logging.getLogger(__name__)

# Single service instance (connection pooling benefits)
service = JioSaavnService()

# FIX #12: Helper function to add Cache-Control headers
def add_cache_headers(response, cache_control='max-age=3600, public'):
    """Add Cache-Control header to response for caching optimization."""
    response['Cache-Control'] = cache_control
    return response

# FIX #19: Standardized error responses
def error_response(message, status_code=400, details=None):
    """
    Return standardized error response format.
    Ensures consistent error handling across all endpoints.
    """
    data = {
        'error': message,
        'status': 'error',
        'status_code': status_code,
    }
    if details:
        data['details'] = details
    return JsonResponse(data, status=status_code)

def success_response(data, message='Success', status_code=200):
    """Return standardized success response format."""
    response_data = {
        'data': data,
        'status': 'success',
        'message': message,
    }
    return JsonResponse(response_data, status=status_code)


@require_GET
def search_songs(request):
    """Search for songs by query. FIX #12: Cached search results."""
    query = request.GET.get("q", "").strip()
    limit = min(int(request.GET.get("limit", 20)), 50)

    if not query:
        return JsonResponse({"results": []})

    results = service.search(query, limit=limit)
    response = JsonResponse({
        "results": results,
        "count": len(results),
    })
    # FIX #12: Cache search results for 30 minutes (queries are stable)
    return add_cache_headers(response, 'max-age=1800, public')


@require_GET
def stream_song(request, song_id):
    """
    Stream audio by proxying from upstream CDN.
    
    FIX #23: Always proxy the audio stream.
    This ensures mobile players receive audio data, not JSON.
    The Flutter app calls this endpoint directly and expects audio bytes.
    """
    preferred_quality = request.GET.get("quality", "320")
    
    # Validate song ID
    if not service._validate_id(song_id):
        return JsonResponse({"error": "Invalid song ID"}, status=400)
    
    # Get stream URL from upstream
    stream_url = service.get_stream(song_id, preferred_quality)
    if not stream_url:
        logger.warning(f"Stream not available for song: {song_id}")
        return JsonResponse(
            {"error": "Stream not available for this song"}, 
            status=404
        )
    
    # Always proxy the audio stream
    try:
        # Forward Range header for seeking support
        headers = {
            "User-Agent": "VILLEN-Music/1.0",
        }
        if "HTTP_RANGE" in request.META:
            headers["Range"] = request.META["HTTP_RANGE"]

        # Stream with generous timeout for slow connections
        upstream_response = requests.get(
            stream_url, 
            stream=True, 
            timeout=30,
            headers=headers
        )
        upstream_response.raise_for_status()
        
        response = StreamingHttpResponse(
            upstream_response.iter_content(chunk_size=8192),
            content_type=upstream_response.headers.get("Content-Type", "audio/mpeg"),
            status=upstream_response.status_code
        )
        
        # Forward important headers for seeking and caching
        if "Content-Length" in upstream_response.headers:
            response["Content-Length"] = upstream_response.headers["Content-Length"]
        for header in ["Content-Range", "Accept-Ranges", "Cache-Control", "ETag"]:
            if header in upstream_response.headers:
                response[header] = upstream_response.headers[header]
        
        # Ensure seeking is supported
        if "Accept-Ranges" not in response:
            response["Accept-Ranges"] = "bytes"
            
        return response
    except requests.Timeout:
        logger.error(f"Stream proxy timeout for {song_id}")
        return JsonResponse({"error": "Stream server timeout"}, status=504)
    except requests.RequestException as e:
        logger.error(f"Stream proxy error for {song_id}: {e}")
        return JsonResponse({"error": "Failed to proxy stream"}, status=502)


@require_GET
def song_details(request, song_id):
    """Get full song metadata. FIX #12: Cached song metadata."""
    details = service.get_song_details(song_id)

    if not details:
        return JsonResponse({"error": "Song not found"}, status=404)

    response = JsonResponse(details)
    # FIX #12: Song metadata is immutable, cache for 24 hours
    return add_cache_headers(response, 'max-age=86400, public')


@require_GET
def song_lyrics(request, song_id):
    """Get lyrics for a song."""
    lyrics = service.get_lyrics(song_id)

    if not lyrics:
        return JsonResponse({"error": "Lyrics not available"}, status=404)

    return JsonResponse(lyrics)


@require_GET
def song_related(request, song_id):
    """Get related songs/recommendations."""
    limit = min(int(request.GET.get("limit", 10)), 30)
    related = service.get_related(song_id, limit=limit)

    return JsonResponse({
        "results": related,
        "count": len(related),
    })


@require_GET
def album_details(request, album_id):
    """Get album details with track list. FIX #12: Cached album metadata."""
    album = service.get_album(album_id)

    if not album:
        return JsonResponse({"error": "Album not found"}, status=404)

    response = JsonResponse(album)
    # FIX #12: Album metadata is immutable, cache for 24 hours
    return add_cache_headers(response, 'max-age=86400, public')


@require_GET
def artist_details(request, artist_id):
    """Get artist details with top songs. FIX #12: Cached artist metadata."""
    artist = service.get_artist(artist_id)

    if not artist:
        return JsonResponse({"error": "Artist not found"}, status=404)
    
    response = JsonResponse(artist)
    # FIX #12: Artist metadata is immutable, cache for 24 hours
    return add_cache_headers(response, 'max-age=86400, public')

    return JsonResponse(artist)


@require_GET
def trending_songs(request):
    """Get trending/popular songs. FIX #12: Cached for 1 hour."""
    language = request.GET.get("language", "hindi")
    trending = service.get_trending(language=language)

    response = JsonResponse({
        "results": trending,
        "count": len(trending),
        "language": language,
    })
    # FIX #12: Trending data changes slowly, cache for 1 hour
    return add_cache_headers(response, 'max-age=3600, public')


@require_GET
def cache_stats(request):
    """Get cache statistics (debug endpoint)."""
    
    if not request.user.is_staff:
        return JsonResponse({"error": "Unauthorized"}, status=403)
    
    cache_data = cache.get('jio_cache_stats', {})
    return JsonResponse(cache_data)


@require_GET
def get_csrf_token(request):
    """Provide CSRF token to frontend - Fix #3"""
    from django.middleware.csrf import get_token
    token = get_token(request)
    return JsonResponse({'csrftoken': token})

# --------------------
# AUTHENTICATION & SYNC (DRF)
#from django.shortcuts import render
from django.contrib.auth.models import User
from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated
from rest_framework_simplejwt.views import TokenObtainPairView
from rest_framework_simplejwt.tokens import RefreshToken

from .models import LikedSong
from .serializers.auth_serializers import UserRegisterSerializer

class CustomTokenObtainPairView(TokenObtainPairView):
    """
    FIX #22: Custom login view with comprehensive security documentation.
    
    CRITICAL SECURITY IMPLEMENTATION:
    ================================
    Prevents XSS attacks from stealing tokens via localStorage by using HttpOnly cookies.
    
    Key security features:
    1. HttpOnly flag: Prevents JavaScript from accessing tokens
    2. Secure flag: Only sent over HTTPS in production
    3. SameSite=Lax: Protects against CSRF attacks
    4. Tokens removed from response body: Not accessible to client code
    
    Architecture:
    - Access token: 1 hour expiration (short-lived for security)
    - Refresh token: 7 days expiration (longer for user convenience)
    - Automatic refresh: Frontend handles 401 errors by calling /auth/refresh/
    
    Compatibility:
    - Requires credentials: 'include' in all fetch calls (frontend/app.js)
    - CSRF token needed for POST requests (/csrf/ endpoint)
    """
    def post(self, request, *args, **kwargs):
        response = super().post(request, *args, **kwargs)
        
        if response.status_code == 200:
            # Extract tokens from response body
            # These are removed from the response to prevent exposure
            access_token = response.data.get('access')
            refresh_token = response.data.get('refresh')
            
            # Set HttpOnly cookies for security
            # FIX #2, FIX #22: HttpOnly prevents XSS token theft
            response.set_cookie(
                'access_token',
                access_token,
                max_age=3600,  # 1 hour - short lived for security
                httponly=True,  # Prevents JavaScript access (blocks XSS)
                secure=not settings.DEBUG,  # HTTPS only in production
                samesite='Lax',  # CSRF protection
                path='/'
            )
            
            response.set_cookie(
                'refresh_token',
                refresh_token,
                max_age=7 * 24 * 3600,  # 7 days - longer lived, less frequently sent
                httponly=True,  # Prevents JavaScript access (blocks XSS)
                secure=not settings.DEBUG,  # HTTPS only in production
                samesite='Lax',  # CSRF protection
                path='/'
            )
            
            # FIX #22: Clear sensitive data from response body
            # Tokens are now ONLY in secure cookies
            # Frontend cannot access them via JavaScript
            response.data = {
                'status': 'success',
                'message': 'Login successful. Tokens set in secure cookies.'
            }
        
        return response

class LogoutView(APIView):
    """
    Logout view that clears HttpOnly cookies.
    FIX #2: Allows frontend to clear server-side session tokens
    """
    permission_classes = [IsAuthenticated]
    
    def post(self, request):
        """Clear authentication cookies"""
        response = Response(
            {'status': 'success', 'message': 'Logged out successfully'},
            status=200
        )
        
        # Clear HttpOnly cookies
        response.delete_cookie('access_token', path='/')
        response.delete_cookie('refresh_token', path='/')
        
        return response

class RegisterView(generics.CreateAPIView):
    queryset = User.objects.all()
    permission_classes = (permissions.AllowAny,)
    serializer_class = UserRegisterSerializer

class ManageLikesView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        """Get all liked songs for the user."""
        likes = LikedSong.objects.filter(user=request.user).order_by('-created_at')
        serializer = LikedSongSerializer(likes, many=True)
        return Response(serializer.data)

    def post(self, request):
        """Sync a liked song (add if not exists)."""
        data = request.data.copy()
        
        # Validation checks
        if not data.get('song_id'):
            return Response({"error": "song_id required"}, status=400)

        # Update or create logic to prevent duplicates
        obj, created = LikedSong.objects.update_or_create(
            user=request.user,
            song_id=data['song_id'],
            defaults={
                'title': data.get('title', 'Unknown'),
                'artist': data.get('artist', 'Unknown'),
                'image': data.get('image', ''),
                'duration': data.get('duration', 0)
            }
        )
        return Response({"status": "synced", "created": created}, status=200)

    def delete(self, request):
        """Remove a liked song."""
        song_id = request.data.get('song_id') or request.query_params.get('song_id')
        if not song_id:
             return Response({"error": "song_id required"}, status=400)
        
        LikedSong.objects.filter(user=request.user, song_id=song_id).delete()
        return Response({"status": "removed"}, status=200)
