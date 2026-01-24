# VILLEN Music API Documentation

## Overview

VILLEN Music API is a RESTful service providing endpoints for music streaming, authentication, and user data management. All responses are JSON-formatted, and authentication uses JWT tokens.

**Base URL:** `https://api.villen-music.com/api/` (Production) / `http://localhost:8000/api/` (Local)

---

## Authentication

### JWT Token Flow

1. User logs in with credentials → receives `access` and `refresh` tokens
2. Include `access` token in `Authorization: Bearer <token>` header for authenticated requests
3. Token expires after **1 hour**
4. Use `refresh` endpoint to get new `access` token without re-login

### Endpoints

#### POST `/auth/login/`
Login and get access/refresh tokens.

**Request:**
```json
{
  "username": "user123",
  "password": "SecurePass123!"
}
```

**Response (200 OK):**
```json
{
  "access": "eyJhbGc...",
  "refresh": "eyJhbGc...",
  "user": {
    "id": 1,
    "username": "user123",
    "email": "user@example.com"
  }
}
```

**Error (401 Unauthorized):**
```json
{
  "error": "Invalid credentials",
  "status": "error"
}
```

---

#### POST `/auth/refresh/`
Refresh access token using refresh token.

**Request:**
```json
{
  "refresh": "eyJhbGc..."
}
```

**Response (200 OK):**
```json
{
  "access": "eyJhbGc...",
  "status": "success"
}
```

---

#### POST `/auth/logout/`
Logout and clear session (HttpOnly cookies).

**Request:**
```
No body required. Include Authorization header.
```

**Response (200 OK):**
```json
{
  "message": "Logged out successfully",
  "status": "success"
}
```

---

#### POST `/auth/register/`
Register new user account.

**Request:**
```json
{
  "username": "newuser",
  "email": "newuser@example.com",
  "password": "SecurePass123!"
}
```

**Validation:**
- Username: 3-30 characters, alphanumeric + underscore
- Email: Valid email format
- Password: Minimum 8 characters, must contain uppercase, lowercase, number, and special character

**Response (201 Created):**
```json
{
  "id": 2,
  "username": "newuser",
  "email": "newuser@example.com"
}
```

**Error (400 Bad Request):**
```json
{
  "error": "Username already exists",
  "status": "error",
  "field": "username"
}
```

---

## Music Endpoints

All music endpoints require authentication unless noted as public.

### GET `/search/?q=<query>&limit=30`
Search for songs, artists, or albums.

**Query Parameters:**
- `q` (required): Search query (min 2 characters)
- `limit` (optional): Results per page, default 30, max 100

**Response (200 OK):**
```json
{
  "results": [
    {
      "id": "song_123",
      "title": "Song Title",
      "artist": "Artist Name",
      "album": "Album Name",
      "duration": 240,
      "image_url": "https://...",
      "language": "hindi"
    }
  ],
  "status": "success"
}
```

**Cache-Control:** 30 minutes (results are stable)

---

### GET `/trending/?language=hindi`
Get trending songs.

**Query Parameters:**
- `language` (optional): Language filter (hindi, english, punjabi, etc.), default all

**Response (200 OK):**
```json
{
  "results": [
    {
      "id": "song_123",
      "title": "Trending Song",
      "artist": "Artist Name",
      "plays": 100000,
      "image_url": "https://..."
    }
  ],
  "status": "success"
}
```

**Cache-Control:** 1 hour (trending data updates slowly)

---

### GET `/song/<song_id>/`
Get song details.

**Path Parameters:**
- `song_id` (required): Unique song identifier

**Response (200 OK):**
```json
{
  "data": {
    "id": "song_123",
    "title": "Song Title",
    "artist": "Artist Name",
    "album": "Album Name",
    "duration": 240,
    "release_date": "2024-01-15",
    "language": "hindi",
    "image_url": "https://...",
    "lyrics_available": true
  },
  "status": "success"
}
```

**Cache-Control:** 24 hours (song metadata is immutable)

---

### GET `/song/<song_id>/lyrics/`
Get song lyrics.

**Path Parameters:**
- `song_id` (required): Song ID

**Response (200 OK):**
```json
{
  "data": {
    "lyrics": "[00:00] Verse 1...\n[01:20] Chorus...",
    "has_lyrics": true
  },
  "status": "success"
}
```

**Response (404 Not Found):**
```json
{
  "error": "Lyrics not available",
  "status": "error"
}
```

---

### GET `/song/<song_id>/related/`
Get songs similar to the specified song (auto-queue suggestions).

**Path Parameters:**
- `song_id` (required): Song ID

**Query Parameters:**
- `limit` (optional): Number of suggestions, default 10, max 30

**Response (200 OK):**
```json
{
  "results": [
    {
      "id": "song_456",
      "title": "Similar Song",
      "artist": "Artist Name",
      "similarity_score": 0.92
    }
  ],
  "status": "success"
}
```

---

### GET `/stream/<song_id>/?quality=320`
Get stream URL for song playback.

**Path Parameters:**
- `song_id` (required): Song ID

**Query Parameters:**
- `quality` (optional): Audio quality (128, 192, 320), default 192

**Response (200 OK):**
```json
{
  "url": "https://stream-cdn.example.com/songs/123.mp3",
  "quality": 320,
  "expires_in": 3600,
  "status": "success"
}
```

**Error (404):**
```json
{
  "error": "Stream not available",
  "status": "error"
}
```

**Rate Limiting:** 100 requests per minute per user

---

## User Endpoints

### GET `/user/profile/`
Get current user profile.

**Authentication:** Required (Bearer token)

**Response (200 OK):**
```json
{
  "data": {
    "id": 1,
    "username": "user123",
    "email": "user@example.com",
    "profile_image": "https://...",
    "created_at": "2024-01-01",
    "liked_songs_count": 42,
    "playlists_count": 3
  },
  "status": "success"
}
```

---

### PUT `/user/profile/`
Update user profile.

**Authentication:** Required

**Request:**
```json
{
  "email": "newemail@example.com",
  "profile_image": "base64_string_or_url"
}
```

**Response (200 OK):**
```json
{
  "data": {
    "id": 1,
    "username": "user123",
    "email": "newemail@example.com"
  },
  "status": "success"
}
```

---

### POST `/user/change-password/`
Change user password.

**Authentication:** Required

**Request:**
```json
{
  "old_password": "CurrentPass123!",
  "new_password": "NewPass123!"
}
```

**Response (200 OK):**
```json
{
  "message": "Password changed successfully",
  "status": "success"
}
```

---

### GET `/user/liked-songs/`
Get user's liked songs.

**Authentication:** Required

**Query Parameters:**
- `page` (optional): Page number for pagination, default 1
- `limit` (optional): Items per page, default 20

**Response (200 OK):**
```json
{
  "results": [
    {
      "id": "song_123",
      "title": "Liked Song",
      "artist": "Artist Name"
    }
  ],
  "total": 42,
  "page": 1,
  "status": "success"
}
```

---

### POST `/user/liked-songs/<song_id>/`
Like a song.

**Authentication:** Required

**Response (201 Created):**
```json
{
  "message": "Song liked",
  "status": "success"
}
```

---

### DELETE `/user/liked-songs/<song_id>/`
Unlike a song.

**Authentication:** Required

**Response (204 No Content)**

---

## Error Responses

All errors follow standard format:

```json
{
  "error": "Error message",
  "status": "error",
  "details": {}
}
```

### Common Error Codes

| Status | Code | Meaning |
|--------|------|---------|
| 400 | `validation_error` | Invalid input |
| 401 | `unauthorized` | Missing/invalid token |
| 403 | `forbidden` | Access denied |
| 404 | `not_found` | Resource not found |
| 429 | `rate_limit` | Too many requests |
| 500 | `server_error` | Server error |

---

## Rate Limiting

- **General API:** 120 requests per 60 seconds per user
- **Search:** 30 requests per minute
- **Stream:** 100 requests per minute
- **Admin Endpoints:** 5 attempts per 5 minutes

When rate limit exceeded:
```json
{
  "error": "Rate limit exceeded. Try again in 30 seconds.",
  "status": "error",
  "retry_after": 30
}
```

---

## Caching Strategy

**Frontend Cache (5-minute TTL):**
- Search results
- Artist information
- Album information
- Lyrics

**Server Cache-Control Headers:**
- Search results: `Cache-Control: max-age=1800` (30 min)
- Trending: `Cache-Control: max-age=3600` (1 hour)
- Metadata: `Cache-Control: max-age=86400` (24 hours)

---

## Security Headers

All responses include:
- `Strict-Transport-Security: max-age=31536000` (HSTS - 1 year)
- `Content-Security-Policy: default-src 'self'`
- `X-Frame-Options: DENY`
- `X-Content-Type-Options: nosniff`

---

## Pagination

Endpoints returning lists support pagination:

```json
{
  "results": [...],
  "total": 150,
  "page": 1,
  "page_size": 20,
  "total_pages": 8
}
```

---

## WebSocket (Real-time Features)

Upcoming in v2.0:
- Real-time notifications
- Live chat
- Collaborative playlists

---

## SDK/Client Libraries

- **JavaScript:** `villen-music-js-sdk` (NPM)
- **Flutter:** Built-in in mobile app
- **Python:** `villen-music-python` (PyPI)

---

## Support

For API issues:
- **Documentation:** https://docs.villen-music.com
- **Issues:** https://github.com/villen-music/api/issues
- **Email:** support@villen-music.com

---

**Last Updated:** 2024-01-15
**API Version:** 1.0.0
