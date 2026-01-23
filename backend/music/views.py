# backend/music/views.py

import requests
from django.http import StreamingHttpResponse
from django.http import JsonResponse
from django.views.decorators.http import require_GET

from .services.jiosaavn_service import JioSaavnService

# Single service instance (connection pooling benefits)
service = JioSaavnService()


@require_GET
def search_songs(request):
    """Search for songs by query."""
    query = request.GET.get("q", "").strip()
    limit = min(int(request.GET.get("limit", 20)), 50)

    if not query:
        return JsonResponse({"results": []})

    results = service.search(query, limit=limit)
    return JsonResponse({
        "results": results,
        "count": len(results),
    })


@require_GET
def stream_song(request, song_id):
    """Proxy stream for a song with Range support (Partial Content)."""
    preferred_quality = request.GET.get("quality", "320")
    stream_url = service.get_stream(song_id, preferred_quality)

    if not stream_url:
        return JsonResponse({"error": "Stream not available"}, status=404)

    # Proxy the stream
    try:
        # Forward Range header if present
        headers = {}
        if "HTTP_RANGE" in request.META:
            headers["Range"] = request.META["HTTP_RANGE"]

        # Stream=True is critical
        upstream_response = requests.get(
            stream_url, 
            stream=True, 
            timeout=10,
            headers=headers
        )
        
        response = StreamingHttpResponse(
            upstream_response.iter_content(chunk_size=8192),
            content_type=upstream_response.headers.get("Content-Type", "audio/mpeg"),
            status=upstream_response.status_code
        )
        
        # Forward relevant headers for buffering
        for header in ["Content-Length", "Content-Range", "Accept-Ranges"]:
            if header in upstream_response.headers:
                response[header] = upstream_response.headers[header]
        
        # Fallback if upstream doesn't send Accept-Ranges but supports it
        if "Accept-Ranges" not in response:
            response["Accept-Ranges"] = "bytes"
        
        return response
    except requests.RequestException as e:
        return JsonResponse({"error": "Stream proxy failed"}, status=502)


@require_GET
def song_details(request, song_id):
    """Get full song metadata."""
    details = service.get_song_details(song_id)

    if not details:
        return JsonResponse({"error": "Song not found"}, status=404)

    return JsonResponse(details)


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
    """Get album details with track list."""
    album = service.get_album(album_id)

    if not album:
        return JsonResponse({"error": "Album not found"}, status=404)

    return JsonResponse(album)


@require_GET
def artist_details(request, artist_id):
    """Get artist details with top songs."""
    artist = service.get_artist(artist_id)

    if not artist:
        return JsonResponse({"error": "Artist not found"}, status=404)

    return JsonResponse(artist)


@require_GET
def trending_songs(request):
    """Get trending/popular songs."""
    language = request.GET.get("language", "hindi")
    trending = service.get_trending(language=language)

    return JsonResponse({
        "results": trending,
        "count": len(trending),
        "language": language,
    })


@require_GET
def cache_stats(request):
    """Get cache statistics (debug endpoint)."""

# --------------------
# AUTHENTICATION & SYNC (DRF)
#from django.shortcuts import render
from django.contrib.auth.models import User
from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated

from .models import LikedSong
from .serializers.auth_serializers import UserRegisterSerializer

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
