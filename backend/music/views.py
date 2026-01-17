# backend/music/views.py

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
    """Get stream URL for a song with quality fallback."""
    preferred_quality = request.GET.get("quality", "320")
    stream_url = service.get_stream(song_id, preferred_quality)

    if not stream_url:
        return JsonResponse({"error": "Stream not available"}, status=404)

    return JsonResponse({"url": stream_url, "quality": preferred_quality})


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
    return JsonResponse(service.cache_stats())
