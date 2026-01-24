# FIXES - Song Playback Issues

## FIX #1: Make AudioHandler Initialization Synchronous

**File:** `lib/services/audio_handler.dart`

The constructor must complete before returning. Change `_init()` from async to sync:

```dart
VillenAudioHandler() {
  // Init Equalizer (safely)
  try {
    _equalizer = AndroidEqualizer();
  } catch (e) {
    debugPrint("Equalizer not available: $e");
    _equalizer = null;
  }
  
  // Init Player with Pipeline (if equalizer available)
  _player = AudioPlayer(
    audioPipeline: _equalizer != null 
      ? AudioPipeline(androidAudioEffects: [_equalizer!])
      : null,
  );
  
  // Initialize synchronously
  _initSync();
}

void _initSync() {
  // Default empty playlist
  _playlist = ConcatenatingAudioSource(children: []);
  
  try {
    // Use a separate async block to initialize the player
    _initAsync();
  } catch (e) {
    debugPrint("Error scheduling player init: $e");
  }
}

void _initAsync() async {
  try {
    await _player.setAudioSource(_playlist!);
    // Enable equalizer if available
    if (_equalizer != null) {
      await _equalizer!.setEnabled(true);
    }
    debugPrint("✅ Audio player initialized successfully");
  } catch (e) {
    debugPrint("❌ Error initializing audio player: $e");
  }
}
```

---

## FIX #2: Add Stream URL Validation

**File:** `lib/services/api_service.dart`

Make `getStreamUrl()` actually fetch and validate:

```dart
/// Get Stream URL with validation
Future<String?> getStreamUrl(String songId, {String quality = '320'}) async {
  try {
    // Use the backend's JSON mode to get actual URL
    final response = await _dio.get(
      '${ApiConstants.baseUrl}/api/stream/$songId/',
      queryParameters: {'quality': quality},
      options: Options(
        headers: {'Accept': 'application/json'},  // Request JSON response
      ),
    );
    
    if (response.statusCode == 200) {
      final url = response.data['url'];
      if (url != null && url.toString().isNotEmpty) {
        debugPrint('✅ Stream URL obtained: $songId @ ${response.data['quality']}');
        return url.toString();
      }
    }
    
    debugPrint('❌ Stream URL is null or empty for song: $songId');
    return null;
  } on DioException catch (e) {
    if (e.response?.statusCode == 404) {
      debugPrint('❌ Song not found or stream unavailable: $songId');
    } else {
      debugPrint('❌ Error fetching stream URL: ${e.message}');
    }
    return null;
  } catch (e) {
    debugPrint('❌ Unexpected error getting stream: $e');
    return null;
  }
}
```

---

## FIX #3: Synchronize Queue with Audio Playback

**File:** `lib/providers/audio_provider.dart`

Make `playSong()` update the music queue:

```dart
Future<void> playSong(Song song) async {
  try {
    debugPrint("🎵 Playing song: ${song.title}");
    
    // 1. Resolve the stream URL
    final url = await _resolveUrl(song);
    if (url == null) {
      debugPrint("❌ Failed to get stream URL for: ${song.title}");
      // TODO: Show error to user
      return;
    }
    
    debugPrint("✅ Stream URL resolved: $url");
    
    // 2. Update the music provider queue to match
    // THIS IS CRITICAL: Sync the two state sources
    final musicProvider = /* Get from context or pass as param */;
    musicProvider.setQueue([song], startIndex: 0);
    await musicProvider.addToRecentlyPlayed(song);
    
    // 3. Play in audio handler
    await _audioHandler.playSong(song, url);
    
  } catch (e) {
    debugPrint("❌ Error playing song: $e");
    // TODO: Show error to user via ScaffoldMessenger
  }
}
```

**Issue:** The above requires passing context. Better approach - refactor to use callbacks:

```dart
/// Callback when a song is about to play
/// Screens should use this to update queue
void Function(Song)? onSongStarting;

Future<void> playSong(Song song) async {
  try {
    final url = await _resolveUrl(song);
    if (url == null) {
      debugPrint("❌ Failed to get stream URL");
      return;
    }
    
    // Notify listeners to update queue
    onSongStarting?.call(song);
    
    await _audioHandler.playSong(song, url);
  } catch (e) {
    debugPrint("❌ Error playing song: $e");
  }
}
```

---

## FIX #4: Improve AudioHandler Playlist Management

**File:** `lib/services/audio_handler.dart`

```dart
/// Start a new queue with this song
Future<void> playSong(Song song, String streamUrl) async {
  try {
    debugPrint("🎵 [AudioHandler] Playing: ${song.title}");
    
    // Validate URL before creating source
    if (streamUrl.isEmpty) {
      throw Exception("Stream URL is empty");
    }
    
    final source = _createSource(song, streamUrl);
    
    // Create fresh playlist with one song
    _playlist = ConcatenatingAudioSource(children: [source]);
    
    // Set audio source and wait for it to complete
    await _player.setAudioSource(_playlist!);
    debugPrint("✅ Audio source set: ${song.title}");
    
    // Now play (also awaited)
    await _player.play();
    debugPrint("▶️ Playback started");
    
  } catch (e) {
    debugPrint("❌ [AudioHandler] Error playing audio: $e");
    rethrow;  // Propagate to UI layer
  }
}

/// Add a song to the end of the current playlist (for pre-buffering)
Future<void> addNext(Song song, String streamUrl) async {
  try {
    if (_playlist == null) {
      debugPrint("⚠️ [AudioHandler] Playlist not initialized, creating new one");
      await playSong(song, streamUrl);
      return;
    }
    
    final source = _createSource(song, streamUrl);
    await _playlist!.add(source);
    debugPrint("✅ Song queued: ${song.title}");
  } catch (e) {
    debugPrint("❌ [AudioHandler] Error adding song: $e");
  }
}

AudioSource _createSource(Song song, String streamUrl) {
  return LockCachingAudioSource(
    Uri.parse(streamUrl),
    tag: MediaItem(
      id: song.id,
      album: song.album ?? "Single",
      title: song.title,
      artist: song.artist,
      artUri: song.image != null ? Uri.parse(song.image!) : null,
      duration: Duration(seconds: song.duration is int ? song.duration : 0),
      extras: {
        'url': streamUrl,
        'songId': song.id,
      },
    ),
  );
}
```

---

## FIX #5: Platform-Specific Equalizer Initialization

**File:** `lib/services/audio_handler.dart`

```dart
import 'dart:io' show Platform;

VillenAudioHandler() {
  // Init Equalizer (Android only)
  if (Platform.isAndroid) {
    try {
      _equalizer = AndroidEqualizer();
      debugPrint("✅ Equalizer initialized (Android)");
    } catch (e) {
      debugPrint("⚠️ Equalizer initialization failed: $e");
      _equalizer = null;
    }
  } else {
    _equalizer = null;
    debugPrint("ℹ️ Equalizer not available on ${Platform.operatingSystem}");
  }
  
  // Init Player with Pipeline
  _player = AudioPlayer(
    audioPipeline: _equalizer != null
        ? AudioPipeline(androidAudioEffects: [_equalizer!])
        : null,
  );
  
  _initAsync();
}

void _initAsync() async {
  _playlist = ConcatenatingAudioSource(children: []);
  
  try {
    await _player.setAudioSource(_playlist!);
    if (_equalizer != null) {
      await _equalizer!.setEnabled(true);
    }
    debugPrint("✅ Audio system ready");
  } catch (e) {
    debugPrint("❌ Audio initialization error: $e");
  }
}
```

---

## FIX #6: Explicit Content Negotiation in Backend

**File:** `backend/music/views.py`

```python
@require_GET
def stream_song(request, song_id):
    """
    Stream song audio with explicit content negotiation.
    
    Query Parameters:
      - quality: audio quality (320, 160, 96, etc.)
    
    Returns:
      - JSON if Accept: application/json header present
      - Audio stream otherwise
    """
    preferred_quality = request.GET.get("quality", "320")
    
    if not service._validate_id(song_id):
        return JsonResponse({"error": "Invalid song ID"}, status=400)
    
    # 1. Get stream URL
    stream_url = service.get_stream(song_id, preferred_quality)
    if not stream_url:
        return JsonResponse(
            {"error": "Stream not available for this song"}, 
            status=404
        )
    
    # 2. Check Accept header for content negotiation
    accept_header = request.headers.get("Accept", "").lower()
    if "application/json" in accept_header:
        # Return JSON with URL (for API clients)
        return JsonResponse({
            "url": stream_url,
            "quality": preferred_quality,
            "songId": song_id,
        })
    
    # 3. Default: Proxy the audio stream
    try:
        # Forward Range header for seeking support
        headers = {}
        if "HTTP_RANGE" in request.META:
            headers["Range"] = request.META["HTTP_RANGE"]
        
        # Fetch upstream
        upstream_response = requests.get(
            stream_url,
            stream=True,
            timeout=15,
            headers=headers
        )
        upstream_response.raise_for_status()
        
        # Create response with proper audio headers
        response = StreamingHttpResponse(
            upstream_response.iter_content(chunk_size=8192),
            content_type=upstream_response.headers.get("Content-Type", "audio/mpeg"),
            status=upstream_response.status_code
        )
        
        # Forward safe headers
        for header in ["Content-Range", "Accept-Ranges", "Cache-Control", "ETag"]:
            if header in upstream_response.headers:
                response[header] = upstream_response.headers[header]
        
        # Ensure seeking is supported
        if "Accept-Ranges" not in response:
            response["Accept-Ranges"] = "bytes"
        
        return response
        
    except requests.Timeout:
        return JsonResponse(
            {"error": "Stream server timeout"}, 
            status=504
        )
    except requests.RequestException as e:
        logger.error(f"Stream proxy error for {song_id}: {e}")
        return JsonResponse(
            {"error": "Failed to proxy stream"}, 
            status=502
        )
```

---

## FIX #7: Add Timeout and Error Feedback to AudioProvider

**File:** `lib/providers/audio_provider.dart`

```dart
Future<void> playSong(Song song) async {
  try {
    debugPrint("🎵 Attempting to play: ${song.title}");
    
    // Resolve URL with timeout
    final url = await _resolveUrl(song).timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        throw TimeoutException("Failed to get stream URL after 30 seconds");
      },
    );
    
    if (url == null) {
      _showError("Stream not available for this song");
      return;
    }
    
    // Play with timeout
    await _audioHandler.playSong(song, url).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        throw TimeoutException("Playback initialization timed out");
      },
    );
    
    debugPrint("✅ Now playing: ${song.title}");
    
  } on TimeoutException catch (e) {
    debugPrint("⏱️ Timeout: $e");
    _showError("Network connection too slow. Check your internet.");
  } on Exception catch (e) {
    debugPrint("❌ Playback error: $e");
    _showError("Failed to play song. Please try again.");
  }
}

void _showError(String message) {
  // Show snackbar to user
  ScaffoldMessenger.of(_context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
      duration: const Duration(seconds: 3),
    ),
  );
}

Future<String?> _resolveUrl(Song song) async {
  // Try local first
  final localPath = await _downloadService.getLocalPath(song.id);
  if (localPath != null) {
    debugPrint("📱 Using local file: ${song.title}");
    return Uri.file(localPath).toString();
  }
  
  // Fall back to stream
  debugPrint("🌐 Requesting stream for: ${song.title}");
  final url = await _apiService.getStreamUrl(song.id);
  
  if (url == null) {
    debugPrint("❌ No stream URL available");
  }
  
  return url;
}
```

---

## Testing Checklist

After applying fixes, test:

- [ ] **Basic Play** - Tap song, does audio play?
- [ ] **Error Message** - Disable WiFi, try play, see error?
- [ ] **Queue Sync** - Play song, check if queue updates
- [ ] **Next/Previous** - Does skip work?
- [ ] **Auto-queue** - Does next song auto-play?
- [ ] **Timeout** - Slow network, app doesn't freeze?
- [ ] **Platform** - Test on Android and iOS
- [ ] **Stream URL** - Check backend logs for successful requests

---

## Debugging Commands

```bash
# Check Android logs
adb logcat | grep -E "(just_audio|AudioHandler|Error playing)"

# Test backend stream endpoint
curl -H "Accept: application/json" \
  "http://localhost:8000/api/stream/SONG_ID/?quality=320"

# Check Django cache
python manage.py shell
>>> from django.core.cache import cache
>>> data = cache.get('song:SONG_ID')
>>> print(data)
```
