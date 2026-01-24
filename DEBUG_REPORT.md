# VILLEN Music - Song Playback Debug Report

## Overview
Songs show metadata (title, artist, album art) but audio doesn't play. The issue is **NOT in the UI layer** but in the **Audio Initialization and Playback Pipeline**.

---

## ROOT CAUSES IDENTIFIED

### 🔴 **CRITICAL ISSUE #1: AudioHandler._init() is Async but Not Awaited**

**File:** [`lib/services/audio_handler.dart`](lib/services/audio_handler.dart#L30-L41)

**Problem:**
```dart
VillenAudioHandler() {
  _equalizer = AndroidEqualizer();
  _player = AudioPlayer(audioStack: [_equalizer!]);
  _init();  // ❌ NOT AWAITED! This is an async method called without await
}

void _init() async {  // ❌ ASYNC but not awaited
  _playlist = ConcatenatingAudioSource(children: []);
  try {
    await _player.setAudioSource(_playlist!);  // This completes in background
    await _equalizer?.setEnabled(true);
  } catch (e) {
    debugPrint("Error initializing player: $e");
  }
}
```

**Impact:**
- The constructor returns BEFORE `setAudioSource()` completes
- When `playSong()` is called immediately after, `_playlist` might still be null or not properly initialized
- Audio source setup races with the play command
- Results in buffering indefinitely or silent playback

**Solution:**
Constructor should be async or `_init()` must complete before returning.

---

### 🔴 **CRITICAL ISSUE #2: Missing Error Handling in Stream URL**

**File:** [`lib/services/api_service.dart`](lib/services/api_service.dart#L155-L160)

**Problem:**
```dart
Future<String?> getStreamUrl(String songId, {String quality = '320'}) async {
  return '${ApiConstants.baseUrl}/stream/$songId/?quality=$quality';
}
```

**Impact:**
- URL is constructed but NEVER VALIDATED
- No check if the backend can actually stream this song
- If JioSaavn service fails to fetch the song, the URL will still be constructed
- Just Audio tries to play a non-existent/invalid URL silently
- No error feedback to user

**Root Issue in Backend:**
[`backend/music/services/jiosaavn_service.py`](backend/music/services/jiosaavn_service.py#L115-L135)

```python
def get_stream(self, song_id: str, preferred_quality: str = "320") -> Optional[str]:
    song_data = self._fetch_song_data(song_id)
    if not song_data:
        return None  # ✅ Returns None correctly
    
    downloads = song_data.get("downloadUrl", [])
    if not downloads:
        return None  # ✅ This is good
    # ... quality fallback
```

The backend correctly returns `None` when stream fails, but the Flutter app **ignores this**!

---

### 🔴 **CRITICAL ISSUE #3: Missing Queue Association**

**File:** [`lib/providers/audio_provider.dart`](lib/providers/audio_provider.dart#L92-L102)

**Problem:**
```dart
Future<void> playSong(Song song) async {
  try {
    final url = await _resolveUrl(song);
    if (url != null) {
      debugPrint("Playing song: ${song.title}");
      await _audioHandler.playSong(song, url);
    }
  } catch (e) {
    debugPrint("Error playing song: $e");
  }
}
```

**Issue:** 
- `playSong()` is called directly without setting up queue context
- The `MusicProvider` queue is NOT synchronized with `AudioProvider`
- When `playSong()` is called from HomeScreen, it bypasses the queue system entirely
- This means `music.currentSong` and `audio.currentSong` can be different objects
- The player has no reference to next/previous songs
- Auto-queue logic in `main_screen.dart` waits for `musicProvider.currentSong` which never updates

**Example Flow:**
1. User taps song in HomeScreen
2. `audio.playSong(song)` called directly
3. `music.currentSong` is still the old song (or null)
4. `audio.currentSong` is now the new song
5. Two state sources diverge → logic breaks

---

### 🟡 **ISSUE #4: AudioHandler Playlist Management is Fragile**

**File:** [`lib/services/audio_handler.dart`](lib/services/audio_handler.dart#L65-L85)

**Problem:**
```dart
Future<void> playSong(Song song, String streamUrl) async {
  try {
    final source = _createSource(song, streamUrl);
    
    _playlist = ConcatenatingAudioSource(children: [source]);  // ❌ Creates new playlist each time
    await _player.setAudioSource(_playlist!);
    _player.play();  // ❌ No await
    
  } catch (e) {
    debugPrint("Error playing audio: $e");  // Silent catch
  }
}
```

**Issues:**
1. Creates a NEW `ConcatenatingAudioSource` every play (inefficient)
2. `_player.play()` is not awaited
3. `setAudioSource()` + `play()` happen in parallel, can cause race conditions
4. No validation that stream URL is valid before setting as source
5. Errors are silently logged, not propagated to UI

---

### 🟡 **ISSUE #5: Audio Pipeline May Not Be Initialized**

**File:** [`lib/services/audio_handler.dart`](lib/services/audio_handler.dart#L18-L28)

**Problem:**
```dart
VillenAudioHandler() {
  _equalizer = AndroidEqualizer();
  
  _player = AudioPlayer(
    audioPipeline: AudioPipeline(
      androidAudioEffects: [_equalizer!],
    ),
  );
}
```

**Issues:**
- `AndroidEqualizer()` may return null on non-Android platforms (iOS, Web)
- `AudioPipeline` with null effects could cause initialization failure
- No platform-specific checks
- Android Equalizer initialization can fail silently

---

### 🟡 **ISSUE #6: Stream Validation in Backend**

**File:** [`backend/music/views.py`](backend/music/views.py#L28-L70)

**Problem:**
```python
@require_GET
def stream_song(request, song_id):
    preferred_quality = request.GET.get("quality", "320")
    
    accept_header = request.headers.get("Accept", "")
    if "application/json" in accept_header:
        stream_url = service.get_stream(song_id, preferred_quality)
        if not stream_url:
            return JsonResponse({"error": "Stream not available"}, status=404)
        return JsonResponse({"url": stream_url, "quality": preferred_quality})

    # Proxy mode for audio players
    stream_url = service.get_stream(song_id, preferred_quality)
    if not stream_url:
        return JsonResponse({"error": "Stream not available"}, status=404)
    
    try:
        upstream_response = requests.get(stream_url, stream=True, timeout=10, ...)
        # ...
    except requests.RequestException as e:
        return JsonResponse({"error": "Stream proxy failed"}, status=502)
```

**Issue:**
- When Flutter requests `/api/stream/{song_id}/?quality=320` WITHOUT Accept header, it assumes proxy mode
- But Flutter's `just_audio` may set different headers
- Content-Type negotiation is fragile

**Result:** Audio player gets 404 or 502 responses instead of audio stream

---

### 🟡 **ISSUE #7: No Timeout Handling in AudioProvider**

**File:** [`lib/providers/audio_provider.dart`](lib/providers/audio_provider.dart#L92-L102)

**Problem:**
```dart
Future<void> playSong(Song song) async {
  try {
    final url = await _resolveUrl(song);  // No timeout
    if (url != null) {
      await _audioHandler.playSong(song, url);  // No timeout
    }
  } catch (e) {
    debugPrint("Error playing song: $e");  // User gets no feedback
  }
}
```

**Impact:**
- If backend hangs, app freezes waiting for response
- User sees "playing" but no sound for 30+ seconds
- No retry mechanism
- No user-facing error messages

---

## SUMMARY TABLE

| # | Issue | Severity | Location | Impact |
|---|-------|----------|----------|--------|
| 1 | AudioHandler async init not awaited | 🔴 CRITICAL | `audio_handler.dart:30-41` | Race condition, audio never initializes |
| 2 | No stream URL validation | 🔴 CRITICAL | `api_service.dart:155` | Invalid URLs passed to player |
| 3 | Queue and audio state diverge | 🔴 CRITICAL | `audio_provider.dart:92` | Auto-queue breaks, state confusion |
| 4 | Fragile playlist management | 🟡 HIGH | `audio_handler.dart:65-85` | Race conditions, inefficiency |
| 5 | Audio pipeline null on non-Android | 🟡 HIGH | `audio_handler.dart:18-28` | Playback fails on iOS |
| 6 | Stream content negotiation fragile | 🟡 HIGH | `music/views.py:28-70` | 404/502 errors from backend |
| 7 | No timeout/error feedback | 🟡 MEDIUM | `audio_provider.dart:92` | Poor UX, freezing |

---

## DEBUG CHECKLIST

When debugging, check:

1. **Is AndroidEqualizer available?**
   ```dart
   final equalizer = AndroidEqualizer();
   if (equalizer != null) { /* init */ }
   ```

2. **Does audio source initialize before play?**
   ```dart
   // Check logcat for "Error initializing player"
   adb logcat | grep "Error initializing player"
   ```

3. **Does stream URL return from backend?**
   ```bash
   curl "http://backend/api/stream/SONG_ID/?quality=320"
   # Should return audio stream, not JSON error
   ```

4. **Is song data cached properly?**
   ```python
   # Check Django cache
   python manage.py shell
   >>> from django.core.cache import cache
   >>> cache.get('song:SONG_ID')
   ```

5. **What errors are in Just Audio logs?**
   ```
   Logcat: just_audio
   Look for "Failed to set audio source" or stream URL issues
   ```

---

## NEXT STEPS

See `FIXES.md` for comprehensive solutions to all these issues.
