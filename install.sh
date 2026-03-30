#!/bin/bash
set -e

# SkillDeck Installer
# Usage: curl -fsSL https://raw.githubusercontent.com/pythias/ai-skill-deck/main/install.sh | bash

REPO="pythias/ai-skill-deck"
VERSION=$(curl -s https://api.github.com/repos/$REPO/releases/latest | grep '"tag_name"' | sed 's/.*"v\([^"]*\)".*/\1/')

if [ -z "$VERSION" ]; then
    echo "Error: Could not fetch latest version"
    exit 1
fi

echo "Downloading SkillDeck v$VERSION..."

DMG_URL="https://github.com/$REPO/releases/download/v$VERSION/SkillDeck-macOS.dmg"
DMG_PATH="/tmp/SkillDeck-$VERSION.dmg"
VOLUME="/Volumes/SkillDeck"

# Download
curl -L -o "$DMG_PATH" "$DMG_URL"

# Mount
hdiutil attach "$DMG_PATH" -mountpoint "$VOLUME" -nobrowse

# Install to Applications
cp -R "$VOLUME/SkillDeck.app" /Applications/

# Unmount
hdiutil detach "$VOLUME"

# Cleanup
rm "$DMG_PATH"

echo "SkillDeck v$VERSION installed successfully!"
echo "Open SkillDeck from /Applications/SkillDeck.app"
