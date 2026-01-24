#!/bin/bash

# VILLEN MUSIC LAUNCHER
# This script launches the VILLEN Music application

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if running on different systems
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
    # Windows
    cd "$SCRIPT_DIR/app/windows"
    ./villen-music.exe "$@"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    open "$SCRIPT_DIR/app/macos/villen-music.app"
else
    # Linux
    cd "$SCRIPT_DIR/app/linux"
    ./villen-music "$@"
fi
