#!/bin/bash
set -e

RELEASE_DIR="/home/villen/Desktop/villen-music/app-release/deb"

echo "📦 Building Debian (.deb) package..."
cd "$RELEASE_DIR"

# Build the .deb package
dpkg-deb --build villen-music villen-music_1.0.0_amd64.deb

echo ""
echo "✅ .deb package created!"
echo ""
echo "Installation:"
echo "  sudo apt install ./villen-music_1.0.0_amd64.deb"
echo ""
echo "Or to install from file:"
echo "  sudo dpkg -i villen-music_1.0.0_amd64.deb"
