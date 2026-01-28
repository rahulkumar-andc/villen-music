"""
JioSaavn Music Service - Extended API
- Connection pooling with requests.Session
- Retry logic for transient failures  
- Response caching with TTL
- Single API call for quality fallback
- Enhanced metadata normalization
- Lyrics, Albums, Artists, Related, Trending endpoints
"""

import re
import time
import logging
from typing import Optional, Dict, List, Any

import requests
from django.core.cache import cache
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

logger = logging.getLogger(__name__)

class JioSaavnService:
    BASE_URL = "https://jiosavan-api-pi.vercel.app/api"
    TIMEOUT = 10
    CACHE_TTL = 3600  # 1 hour

    # Valid ID pattern (alphanumeric, typically 4-20 chars)
    ID_PATTERN = re.compile(r"^[a-zA-Z0-9_-]{2,30}$")

    def __init__(self):
        # Connection pooling with retry strategy
        self.session = requests.Session()
        self.session.headers.update({
            "User-Agent": "VILLEN-Music/1.0",
            "Accept": "application/json",
        })

        # Retry on transient failures
        retry_strategy = Retry(
            total=3,
            backoff_factor=0.5,
            status_forcelist=[500, 502, 503, 504],
            allowed_methods=["GET"],
        )
        adapter = HTTPAdapter(max_retries=retry_strategy)
        self.session.mount("https://", adapter)

    # --------------------
    # VALIDATION & CACHING
    # --------------------
    def _validate_id(self, item_id: str) -> bool:
        """Validate ID format to prevent injection attacks."""
        if not item_id or not isinstance(item_id, str):
            return False
        return bool(self.ID_PATTERN.match(item_id))

    def _get_cached(self, key: str) -> Optional[Any]:
        """Get data from cache."""
        return cache.get(key)

    def _set_cache(self, key: str, data: Any):
        """Cache data with standard TTL."""
        cache.set(key, data, timeout=self.CACHE_TTL)
        
    def _cache_songs_from_list(self, songs: list):
        """Optimistically cache individual songs from a list response."""
        if not songs:
            return
            
        count = 0
        for song in songs:
            song_id = song.get("id")
            # Only cache if we have ID and crucial data (downloadUrl or encrypted_media_url)
            if song_id and (song.get("downloadUrl") or song.get("more_info", {}).get("encrypted_media_url")):
                cache_key = f"song:{song_id}"
                # Don't overwrite existing full details if we only have partial, 
                # but search results usually have everything needed for stream.
                self._set_cache(cache_key, song)
                count += 1
        
        if count > 0:
            logger.info(f"Optimistically cached {count} songs")

    def _api_get(self, endpoint: str, params: dict = None) -> Optional[Dict]:
        """Make authenticated API GET request."""
        try:
            response = self.session.get(
                f"{self.BASE_URL}/{endpoint}",
                params=params,
                timeout=self.TIMEOUT,
            )
            response.raise_for_status()
            return response.json()
        except requests.RequestException as e:
            logger.error(f"API request failed: {endpoint} - {e}")
            return None

    # --------------------
    # SEARCH SONGS
    # --------------------
    def search(self, query: str, limit: int = 20) -> List[Dict]:
        """Search for songs with enhanced metadata."""
        if not query or not query.strip():
            return []
            
        # Check cache for query
        cache_key = f"search:{query.strip().lower()}:{limit}"
        cached = self._get_cached(cache_key)
        if cached:
            return cached

        data = self._api_get("search/songs", {"query": query.strip(), "limit": limit})
        if not data:
            return []
            
        raw_results = data.get("data", {}).get("results", [])
        self._cache_songs_from_list(raw_results)

        results = self._normalize_search(data)
        self._set_cache(cache_key, results)
        return results

    def search_artists(self, query: str, limit: int = 10) -> List[Dict]:
        """Search for artists."""
        if not query or not query.strip():
            return []
            
        cache_key = f"search_artist:{query.strip().lower()}:{limit}"
        cached = self._get_cached(cache_key)
        if cached:
            return cached

        data = self._api_get("search/artists", {"query": query.strip(), "limit": limit})
        if not data:
            return []
            
        raw_results = data.get("data", {}).get("results", [])
        results = []
        for item in raw_results:
             results.append({
                 "id": item.get("id"),
                 "name": item.get("name"),
                 "image": self._get_best_image(item.get("image", [])),
                 "type": "artist",
                 "role": item.get("role"),
             })

        self._set_cache(cache_key, results)
        return results

    # --------------------
    # STREAM WITH QUALITY FALLBACK
    # --------------------
    def get_stream(self, song_id: str, preferred_quality: str = "320") -> Optional[str]:
        """Get stream URL with quality fallback - fetches data only once."""
        if not self._validate_id(song_id):
            logger.warning(f"Invalid song ID format: {song_id}")
            return None

        song_data = self._fetch_song_data(song_id)
        if not song_data:
            return None

        downloads = song_data.get("downloadUrl", [])
        if not downloads:
            return None

        preferred = f"{preferred_quality}kbps" if not preferred_quality.endswith("kbps") else preferred_quality
        quality_order = ["320kbps", "160kbps", "96kbps", "48kbps", "12kbps"]

        for quality in [preferred] + [q for q in quality_order if q != preferred]:
            for item in downloads:
                if item.get("quality") == quality:
                    logger.info(f"Stream found: {song_id} @ {quality}")
                    return item.get("url")

        return None

    def _fetch_song_data(self, song_id: str) -> Optional[Dict]:
        """Fetch song data with caching."""
        cache_key = f"song:{song_id}"
        cached = self._get_cached(cache_key)
        if cached:
            return cached

        data = self._api_get(f"songs/{song_id}")
        if not data:
            return None

        songs = data.get("data", [])
        if not songs:
            return None

        song_data = songs[0]
        self._set_cache(cache_key, song_data)
        return song_data

    # --------------------
    # SONG DETAILS
    # --------------------
    def get_song_details(self, song_id: str) -> Optional[Dict]:
        """Get full song details with metadata."""
        if not self._validate_id(song_id):
            return None

        song_data = self._fetch_song_data(song_id)
        if not song_data:
            return None

        return self._normalize_song(song_data)

    # --------------------
    # LYRICS
    # --------------------
    def get_lyrics(self, song_id: str) -> Optional[Dict]:
        """Get lyrics for a song."""
        if not self._validate_id(song_id):
            return None

        cache_key = f"lyrics:{song_id}"
        cached = self._get_cached(cache_key)
        if cached:
            return cached

        data = self._api_get(f"songs/{song_id}/lyrics")
        if not data or not data.get("success"):
            # Fallback: check song data for lyrics
            song_data = self._fetch_song_data(song_id)
            if song_data and not song_data.get("hasLyrics"):
                return {"has_lyrics": False, "lyrics": None}
            return None

        result = {
            "has_lyrics": True,
            "lyrics": data.get("data", {}).get("lyrics"),
            "snippet": data.get("data", {}).get("snippet"),
            "copyright": data.get("data", {}).get("copyright"),
        }
        self._set_cache(cache_key, result)
        return result

    def get_synced_lyrics(self, song_id: str) -> Optional[str]:
        """
        Get synced LRC format lyrics for karaoke mode.
        Returns LRC content string or None if not available.
        """
        if not self._validate_id(song_id):
            return None

        cache_key = f"synced_lyrics:{song_id}"
        cached = self._get_cached(cache_key)
        if cached:
            return cached

        # Try to get synced lyrics from API
        data = self._api_get(f"songs/{song_id}/lyrics")
        if data and data.get("success"):
            lyrics_data = data.get("data", {})
            # Check if we have synced/timed lyrics
            synced_lyrics = lyrics_data.get("syncedLyrics")
            if synced_lyrics:
                self._set_cache(cache_key, synced_lyrics)
                return synced_lyrics
            
            # Try to convert plain lyrics to pseudo-LRC format
            plain_lyrics = lyrics_data.get("lyrics")
            if plain_lyrics:
                # Create simple LRC format (no real timestamps, but shows structure)
                lines = plain_lyrics.split('\n')
                lrc_lines = []
                for i, line in enumerate(lines):
                    # Generate pseudo-timestamps (every ~3 seconds per line)
                    minutes = (i * 3) // 60
                    seconds = (i * 3) % 60
                    lrc_lines.append(f"[{minutes:02d}:{seconds:02d}.00]{line}")
                lrc_content = '\n'.join(lrc_lines)
                self._set_cache(cache_key, lrc_content)
                return lrc_content

        return None


    # --------------------
    # ALBUM
    # --------------------
    def get_album(self, album_id: str) -> Optional[Dict]:
        """Get album details with track list."""
        if not self._validate_id(album_id):
            return None

        cache_key = f"album:{album_id}"
        cached = self._get_cached(cache_key)
        if cached:
            return cached

        data = self._api_get(f"albums", {"id": album_id})
        if not data or not data.get("success"):
            return None

        album_data = data.get("data", {})
        
        # Optimistically cache songs in the album
        self._cache_songs_from_list(album_data.get("songs", []))
        
        result = {
            "id": album_data.get("id"),
            "name": album_data.get("name"),
            "year": album_data.get("year"),
            "release_date": album_data.get("releaseDate"),
            "artist": album_data.get("primaryArtists"),
            "song_count": album_data.get("songCount"),
            "image": self._get_best_image(album_data.get("image", [])),
            "url": album_data.get("url"),
            "songs": [self._normalize_song(s) for s in album_data.get("songs", [])],
        }
        self._set_cache(cache_key, result)
        return result

    # --------------------
    # ARTIST
    # --------------------
    def get_artist(self, artist_id: str) -> Optional[Dict]:
        """Get artist details with top songs."""
        if not self._validate_id(artist_id):
            return None

        cache_key = f"artist:{artist_id}"
        cached = self._get_cached(cache_key)
        if cached:
            return cached

        data = self._api_get(f"artists", {"id": artist_id})
        if not data or not data.get("success"):
            return None

        artist_data = data.get("data", {})
        
        # Optimistically cache top songs
        self._cache_songs_from_list(artist_data.get("topSongs", []))
        
        result = {
            "id": artist_data.get("id"),
            "name": artist_data.get("name"),
            "image": self._get_best_image(artist_data.get("image", [])),
            "url": artist_data.get("url"),
            "follower_count": artist_data.get("followerCount"),
            "fan_count": artist_data.get("fanCount"),
            "is_verified": artist_data.get("isVerified", False),
            "bio": artist_data.get("bio", []),
            "dominant_type": artist_data.get("dominantType"),
            "top_songs": [self._normalize_song(s) for s in artist_data.get("topSongs", [])],
            "top_albums": artist_data.get("topAlbums", []),
        }
        self._set_cache(cache_key, result)
        return result

    # --------------------
    # RELATED SONGS / RECOMMENDATIONS
    # --------------------
    def get_related(self, song_id: str, limit: int = 10) -> List[Dict]:
        """Get enhanced related songs based on language and era."""
        if not self._validate_id(song_id):
            return []

        cache_key = f"related_v2:{song_id}:{limit}"
        cached = self._get_cached(cache_key)
        if cached:
            return cached

        # 1. Get source song details to know language and year
        source_song = self._fetch_song_data(song_id)
        if not source_song:
            return []

        lang = source_song.get("language", "").lower()
        year = int(source_song.get("year") or 0)
        artist = (source_song.get("primaryArtists") or "").split(',')[0].strip()

        # 2. Get API Suggestions
        candidates = []
        data = self._api_get(f"songs/{song_id}/suggestions", {"limit": limit * 2}) # Fetch more to filter
        if data and data.get("success"):
             raw_candidates = data.get("data", [])
             self._cache_songs_from_list(raw_candidates)
             candidates = [self._normalize_song(s) for s in raw_candidates]

        # 3. Filter and Rank
        filtered = []
        
        # Strict Language Filter
        same_lang = [s for s in candidates if s.get("language", "").lower() == lang]
        
        if same_lang:
            # Era Filter (within 5 years) - Give higher score
            scored = []
            for s in same_lang:
                s_year = int(s.get("year") or 0)
                year_diff = abs(s_year - year)
                score = 100 - year_diff # Higher is better
                scored.append((score, s))
            
            scored.sort(key=lambda x: x[0], reverse=True)
            filtered = [s for _, s in scored]
        
        # 4. Fallback: If not enough related songs, search by Artist + Language
        if len(filtered) < 5 and artist and lang:
            logger.info(f"Fallback search for related: {artist} {lang}")
            fallback_query = f"{artist} {lang}"
            search_results = self.search(fallback_query, limit=10)
            
            # Avoid duplicates
            existing_ids = {s['id'] for s in filtered}
            existing_ids.add(song_id)
            
            for s in search_results:
                if s['id'] not in existing_ids and s.get("language", "").lower() == lang:
                     filtered.append(s)

        results = filtered[:limit]
        self._set_cache(cache_key, results)
        return results

    # --------------------
    # TRENDING SONGS
    # --------------------
    def get_trending(self, language: str = "hindi") -> List[Dict]:
        """Get trending/popular songs."""
        cache_key = f"trending:{language}"
        cached = self._get_cached(cache_key)
        if cached:
            return cached

        # Try modules endpoint for trending
        data = self._api_get("modules", {"language": language})
        if data and data.get("success"):
            modules = data.get("data", {})
            trending = modules.get("trending", {})
            
            if trending:
                songs = trending.get("data", [])
                self._cache_songs_from_list(songs)
                result = [self._normalize_song(s) for s in songs if s.get("type") == "song"]
                if result:
                    self._set_cache(cache_key, result)
                    return result

        # Fallback: search for popular songs
        popular_queries = {
            "hindi": "top hindi songs 2024",
            "english": "top english songs 2024",
            "punjabi": "top punjabi songs 2024",
        }
        query = popular_queries.get(language, f"top {language} songs")
        result = self.search(query, limit=20)
        if result:
            self._set_cache(cache_key, result)
        return result

    def _extract_chart_songs(self, chart: dict) -> List[Dict]:
        """Extract songs from a chart/playlist."""
        playlist_id = chart.get("id")
        if not playlist_id:
            return []
        
        data = self._api_get("playlists", {"id": playlist_id})
        if not data or not data.get("success"):
            return []
        
        songs = data.get("data", {}).get("songs", [])
        return [self._normalize_song(s) for s in songs[:20]]

    # --------------------
    # CHARTS
    # --------------------
    def get_charts(self) -> List[Dict]:
        """Get top charts (playlists)."""
        cache_key = "charts:top"
        cached = self._get_cached(cache_key)
        if cached:
            return cached

        # Use modules endpoint to find charts
        data = self._api_get("modules", {"language": "hindi,english"})
        if data and data.get("success"):
            modules = data.get("data", {})
            charts = modules.get("charts", [])
            
            # Normalize charts structure
            result = []
            for chart in charts:
                result.append({
                    "id": chart.get("id"),
                    "title": chart.get("title"),
                    "image": chart.get("image"),
                    "type": "playlist", # Treat as playlist for frontend
                    "song_count": chart.get("count", 0),
                    "subtitle": chart.get("subtitle", "Chart"),
                })
            
            if result:
                self._set_cache(cache_key, result)
                return result
        
        return []


    # --------------------
    # NORMALIZATION HELPERS
    # --------------------
    def _normalize_search(self, data: dict) -> List[Dict]:
        """Normalize search results with enhanced metadata."""
        results = data.get("data", {}).get("results", [])
        return [self._normalize_song(item) for item in results]

    def _normalize_song(self, item: dict) -> Dict[str, Any]:
        """Normalize a single song with all available metadata."""
        album = item.get("album", {})
        
        # Get artist name from various possible locations
        artist = (
            item.get("primaryArtists") or 
            self._extract_artist_names(item.get("artists", {})) or
            "Unknown Artist"
        )

        return {
            "id": item.get("id"),
            "title": item.get("name"),
            "artist": artist,
            "album": album.get("name") if album else None,
            "album_id": album.get("id") if album else None,
            "image": self._get_best_image(item.get("image", [])),
            "images": item.get("image", []),
            "duration": item.get("duration"),
            "year": item.get("year"),
            "language": item.get("language"),
            "has_lyrics": item.get("hasLyrics", False),
            "play_count": item.get("playCount"),
            "url": item.get("url"),
            "explicit": item.get("explicitContent", False),
        }

    def _get_best_image(self, images: list) -> Optional[str]:
        """Get highest quality image URL."""
        if not images:
            return None
        return images[-1].get("url") if isinstance(images[-1], dict) else images[-1]

    def _extract_artist_names(self, artists: dict) -> Optional[str]:
        """Extract artist names from artists object."""
        primary = artists.get("primary", [])
        if primary and isinstance(primary, list):
            return ", ".join(a.get("name", "") for a in primary if a.get("name"))
        return None

    # --------------------
    # CACHE MANAGEMENT
    # --------------------
    def clear_cache(self):
        """Clear the data cache."""
        cache.clear()
        logger.info("Cache cleared")

    def cache_stats(self) -> Dict:
        """Get cache statistics."""
        # Django cache backend agnostic stats are limited
        return {
            "status": "active",
            "backend": str(cache.__class__.__name__),
            "ttl_seconds": self.CACHE_TTL,
        }
