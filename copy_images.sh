#!/bin/bash

# Script to copy card images to iOS simulator Documents directory
# Usage: ./copy_images.sh

echo "🖼️  Copying card images to iOS app..."

# Source directory
SOURCE_DIR="$HOME/data/srg_card_search_website/backend/app/images/mobile"

# Find the app's Documents directory in the simulator
# First, get the app's container
APP_CONTAINER=$(xcrun simctl get_app_container booted com.srg.GetDiced data 2>/dev/null)

if [ -z "$APP_CONTAINER" ]; then
    echo "❌ Error: App container not found. Make sure:"
    echo "   1. The simulator is running"
    echo "   2. The app has been launched at least once"
    echo "   3. The bundle ID is correct (com.srg.GetDiced)"
    exit 1
fi

# Target directory
TARGET_DIR="$APP_CONTAINER/Documents/images/mobile"

echo "📂 Source: $SOURCE_DIR"
echo "📂 Target: $TARGET_DIR"

# Create target directory
mkdir -p "$TARGET_DIR"

# Copy all subdirectories
for subdir in "$SOURCE_DIR"/*; do
    if [ -d "$subdir" ]; then
        dirname=$(basename "$subdir")
        echo "📋 Copying directory: $dirname"
        cp -r "$subdir" "$TARGET_DIR/"
    fi
done

# Count images
IMAGE_COUNT=$(find "$TARGET_DIR" -name "*.webp" | wc -l)
echo "✅ Copied $IMAGE_COUNT images to app Documents directory"
echo "📍 Location: $TARGET_DIR"
echo ""
echo "🎉 Done! Restart the app to see card images."
