# Frontend Connection Test Guide

## Backend Status: ✅ LIVE

**Backend URL:** `https://villen-music.onrender.com/api`

---

## 1. Quick Test in Browser

### Test Trending Songs
Open in browser:
```
https://villen-music.onrender.com/api/trending/
```

You should see a JSON response with trending songs list.

### Test Stream Endpoint
```
https://villen-music.onrender.com/api/stream/U3NBWNJ4/
```
(This will download/stream audio file)

---

## 2. Frontend Configuration (Already Done ✅)

**File:** `frontend/app.js` (Line 9)
```javascript
const API_BASE = "https://villen-music.onrender.com/api";
```

**Status:** ✅ Already configured and ready

---

## 3. Test Frontend Locally

### Option A: Simple Local Server
```bash
cd /home/villen/Desktop/villen-music/frontend
python3 -m http.server 8000
```

Then open: `http://localhost:8000`

### Option B: Using Node.js http-server
```bash
npm install -g http-server
cd /home/villen/Desktop/villen-music/frontend
http-server
```

---

## 4. Testing Song Playback

1. **Open Frontend** → `http://localhost:8000`
2. **Trending Section** → Should load songs from backend
3. **Click Play Button** → Audio should start playing
4. **Check Network Tab** (F12 → Network):
   - `trending/` request → Status 200
   - `stream/...` request → Status 200 (audio file)

---

## 5. Frontend apiFetch Smart Features

### Auto Token Refresh
- If API returns `401`, `apiFetch()` automatically refreshes token
- Then retries the request with new token
- All handled transparently

### Smart Caching
- Search results cached for 5 minutes
- Max 100 entries per cache type
- 5 cache types: search, artist, album, lyrics, trending

### Verified in Code
- **Location:** [frontend/app.js](frontend/app.js#L105)
- **Features:** Automatic 401 handling, cache management, secure API calls

---

## 6. Expected API Responses

### Trending Songs
```json
{
  "results": [
    {
      "id": "U3NBWNJ4",
      "title": "Soulmate",
      "artist": "Badshah, Arijit Singh",
      "album": "Love Anthems 2024",
      "image": "https://c.saavncdn.com/...",
      "duration": 214,
      "url": "https://www.jiosaavn.com/song/..."
    }
  ],
  "count": 20,
  "language": "hindi"
}
```

### Stream Response
- Returns audio file (binary MP3/AAC data)
- Can be played directly in HTML5 `<audio>` tag
- CORS headers configured for cross-origin playback

---

## 7. Troubleshooting

### Issue: 404 Not Found
- Check API_BASE URL in app.js
- Verify backend is running: `curl https://villen-music.onrender.com/api/trending/`

### Issue: CORS Error
- Already fixed in backend settings.py
- `CORS_ALLOWED_ORIGINS` includes all origins in production
- `CORS_ALLOW_CREDENTIALS = True`

### Issue: Audio Not Playing
- Check audio player element has `<audio controls>`
- Verify stream URL is correct
- Check browser console (F12) for errors
- Network tab should show audio file request

### Issue: Token Expired (401)
- `apiFetch()` automatically handles this
- No manual intervention needed
- Check `refreshAccessToken()` function is available

---

## 8. Quick Verification

```bash
# Test API is live
curl https://villen-music.onrender.com/api/trending/ | head -10

# Test search works
curl "https://villen-music.onrender.com/api/search/?q=arijit"

# Test stream endpoint exists
curl -I "https://villen-music.onrender.com/api/stream/U3NBWNJ4/"
```

---

## 9. Next Steps

1. ✅ Backend live and connected
2. ⏳ Start frontend local server: `python3 -m http.server 8000`
3. ⏳ Open browser: `http://localhost:8000`
4. ⏳ Click trending songs to verify playback
5. ⏳ Test search functionality
6. ⏳ Ready to deploy to Vercel/Netlify

---

## 10. Production Frontend Deployment

When ready, deploy frontend to:
- **Vercel** (recommended): `vercel deploy`
- **Netlify**: `netlify deploy`
- **GitHub Pages**: Push to `gh-pages` branch

Both will use the same backend URL: `https://villen-music.onrender.com/api`

All environment handling is already in place!
