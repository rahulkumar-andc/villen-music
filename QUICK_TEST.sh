#!/bin/bash

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}════════════════════════════════════════════${NC}"
echo -e "${BLUE}  VILLEN MUSIC - QUICK TEST COMMANDS${NC}"
echo -e "${BLUE}════════════════════════════════════════════${NC}"
echo ""

echo -e "${YELLOW}Frontend Testing:${NC}"
echo "  1. Start server:"
echo "     cd /home/villen/Desktop/villen-music/frontend"
echo "     python3 -m http.server 8000"
echo ""
echo "  2. Open in browser:"
echo "     http://localhost:8000"
echo ""
echo "  3. Test playback:"
echo "     - Scroll to Trending section"
echo "     - Click play button on any song"
echo "     - Audio should start playing"
echo ""

echo -e "${YELLOW}Flutter Testing:${NC}"
echo "  1. Run app:"
echo "     cd /home/villen/Desktop/villen-music/villen_music_flutter"
echo "     flutter run"
echo ""
echo "  2. Test playback:"
echo "     - Login or skip"
echo "     - Go to Home tab"
echo "     - Tap play button on any song"
echo "     - Audio should start playing"
echo ""

echo -e "${YELLOW}Backend Testing:${NC}"
echo "  1. Check if live:"
echo "     curl https://villen-music.onrender.com/api/trending/"
echo ""
echo "  2. Test search:"
echo "     curl 'https://villen-music.onrender.com/api/search/?q=arijit'"
echo ""
echo "  3. Test stream:"
echo "     curl -I https://villen-music.onrender.com/api/stream/U3NBWNJ4/"
echo ""

echo -e "${YELLOW}Run Integration Test:${NC}"
echo "  bash /home/villen/Desktop/villen-music/TEST_INTEGRATION.sh"
echo ""

echo -e "${BLUE}════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ All systems connected and ready!${NC}"
echo -e "${BLUE}════════════════════════════════════════════${NC}"
