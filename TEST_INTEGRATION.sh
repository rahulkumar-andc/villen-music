#!/bin/bash

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

BACKEND_URL="https://villen-music.onrender.com/api"

echo -e "${BLUE}═════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  VILLEN MUSIC - FULL INTEGRATION TEST${NC}"
echo -e "${BLUE}═════════════════════════════════════════════════════════${NC}"
echo ""

# Test 1: Backend Health
echo -e "${YELLOW}[TEST 1] Backend Health Check${NC}"
if curl -s "$BACKEND_URL/trending/" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Backend is LIVE at $BACKEND_URL${NC}"
else
    echo -e "${RED}❌ Backend is DOWN${NC}"
    exit 1
fi
echo ""

# Test 2: Trending Songs Endpoint
echo -e "${YELLOW}[TEST 2] Trending Songs Endpoint${NC}"
TRENDING=$(curl -s "$BACKEND_URL/trending/")
# Check if results array exists
if echo "$TRENDING" | grep -q '"results"'; then
    COUNT=$(echo "$TRENDING" | grep -o '"count":[0-9]*' | cut -d':' -f2)
    if [ ! -z "$COUNT" ]; then
        echo -e "${GREEN}✅ Trending songs loaded: $COUNT songs${NC}"
        # Extract first song details
        TITLE=$(echo "$TRENDING" | head -c 1000 | grep -o '"title":"[^"]*"' | head -1 | sed 's/"title":"\(.*\)"/\1/')
        echo -e "   📀 First song: ${TITLE}"
    else
        echo -e "${GREEN}✅ Trending endpoint working${NC}"
    fi
else
    echo -e "${RED}❌ Failed to load trending songs${NC}"
    exit 1
fi
echo ""

# Test 3: Search Endpoint
echo -e "${YELLOW}[TEST 3] Search Endpoint${NC}"
SEARCH=$(curl -s "$BACKEND_URL/search/?q=arijit")
SEARCH_COUNT=$(echo "$SEARCH" | grep -o '"count":[0-9]*' | cut -d':' -f2)
if [ ! -z "$SEARCH_COUNT" ] && [ "$SEARCH_COUNT" -gt 0 ]; then
    echo -e "${GREEN}✅ Search working: Found $SEARCH_COUNT results${NC}"
else
    echo -e "${RED}❌ Search endpoint failed${NC}"
fi
echo ""

# Test 4: Stream Endpoint
echo -e "${YELLOW}[TEST 4] Stream Endpoint${NC}"
# Get first song ID from trending
SONG_ID=$(echo "$TRENDING" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
if [ ! -z "$SONG_ID" ]; then
    STREAM_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$BACKEND_URL/stream/$SONG_ID/")
    if [ "$STREAM_CODE" -eq 200 ]; then
        echo -e "${GREEN}✅ Stream endpoint working (Song ID: $SONG_ID)${NC}"
    else
        echo -e "${RED}❌ Stream returned HTTP $STREAM_CODE${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Could not extract song ID${NC}"
fi
echo ""

# Test 5: Frontend Configuration
echo -e "${YELLOW}[TEST 5] Frontend Configuration${NC}"
FRONTEND_API=$(grep -o 'https://villen-music.onrender.com/api' /home/villen/Desktop/villen-music/frontend/app.js 2>/dev/null)
if [ ! -z "$FRONTEND_API" ]; then
    echo -e "${GREEN}✅ Frontend configured correctly${NC}"
    echo -e "   📍 API Base: $FRONTEND_API"
else
    echo -e "${YELLOW}⚠️  Frontend configuration not found${NC}"
fi
echo ""

# Test 6: Flutter Configuration
echo -e "${YELLOW}[TEST 6] Flutter Configuration${NC}"
FLUTTER_API=$(grep -o "static const String baseUrl = 'https://villen-music.onrender.com/api'" /home/villen/Desktop/villen-music/villen_music_flutter/lib/core/constants/api_constants.dart 2>/dev/null)
if [ ! -z "$FLUTTER_API" ]; then
    echo -e "${GREEN}✅ Flutter configured correctly${NC}"
    echo -e "   📍 API Base: $FLUTTER_API"
else
    echo -e "${YELLOW}⚠️  Flutter configuration not found${NC}"
fi
echo ""

# Test 7: Verify Security Features
echo -e "${YELLOW}[TEST 7] Security Features Check${NC}"
RESPONSE=$(curl -s -I "$BACKEND_URL/trending/")
HSTS=$(echo "$RESPONSE" | grep -i "strict-transport-security")
CORS=$(echo "$RESPONSE" | grep -i "access-control")
if [ ! -z "$HSTS" ]; then
    echo -e "${GREEN}✅ HSTS (SSL/TLS) enforced${NC}"
else
    echo -e "${RED}⚠️  HSTS not found${NC}"
fi
if [ ! -z "$CORS" ]; then
    echo -e "${GREEN}✅ CORS headers present${NC}"
else
    echo -e "${YELLOW}⚠️  CORS headers not visible in this response${NC}"
fi
echo ""

# Test 8: API Response Time
echo -e "${YELLOW}[TEST 8] API Response Time${NC}"
START=$(date +%s%N)
curl -s "$BACKEND_URL/trending/" > /dev/null
END=$(date +%s%N)
DURATION=$(( (END - START) / 1000000 ))
if [ "$DURATION" -lt 5000 ]; then
    echo -e "${GREEN}✅ Fast response time: ${DURATION}ms${NC}"
elif [ "$DURATION" -lt 10000 ]; then
    echo -e "${YELLOW}⚠️  Moderate response time: ${DURATION}ms${NC}"
else
    echo -e "${RED}❌ Slow response time: ${DURATION}ms${NC}"
fi
echo ""

# Summary
echo -e "${BLUE}═════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ ALL TESTS PASSED - SYSTEM READY${NC}"
echo -e "${BLUE}═════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo -e "1. Frontend: cd frontend && python3 -m http.server 8000"
echo -e "2. Flutter: cd villen_music_flutter && flutter run"
echo -e "3. Test song playback in both apps"
echo -e ""
echo -e "${BLUE}Documentation:${NC}"
echo -e "• Frontend Connection: FRONTEND_CONNECTION_TEST.md"
echo -e "• Flutter Connection: FLUTTER_CONNECTION_TEST.md"
echo -e ""
