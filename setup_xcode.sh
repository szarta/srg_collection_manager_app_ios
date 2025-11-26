#!/bin/bash

# Get Diced iOS - Xcode Setup Script
# Run this script to configure Xcode and set up the project

set -e  # Exit on error

echo "🚀 Get Diced iOS - Xcode Setup Script"
echo "========================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Step 1: Configure Xcode Command Line Tools
echo -e "${BLUE}Step 1: Configuring Xcode command line tools...${NC}"
if [ ! -d "/Applications/Xcode.app" ]; then
    echo "❌ Xcode not found in /Applications/"
    echo "Please install Xcode from the Mac App Store first."
    exit 1
fi

echo "This requires sudo access (you'll be prompted for your password):"
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -license accept 2>/dev/null || {
    echo "⚠️  You may need to accept the Xcode license manually:"
    echo "   Open Xcode app, or run: sudo xcodebuild -license"
}

echo -e "${GREEN}✓ Xcode configured${NC}"
echo ""

# Step 2: Verify Xcode version
echo -e "${BLUE}Step 2: Verifying Xcode installation...${NC}"
XCODE_VERSION=$(xcodebuild -version | head -1)
echo "   $XCODE_VERSION"
echo -e "${GREEN}✓ Xcode verified${NC}"
echo ""

# Step 3: Check for existing project
echo -e "${BLUE}Step 3: Checking project structure...${NC}"
if [ -f "GetDiced.xcodeproj/project.pbxproj" ]; then
    echo "   ✓ Xcode project already exists"
else
    echo "   ℹ️  No Xcode project found"
    echo "   You'll need to create one using Xcode GUI (see XCODE_PROJECT_SETUP.md)"
fi
echo ""

# Step 4: Copy database file
echo -e "${BLUE}Step 4: Copying database file...${NC}"
DB_SOURCE="../srg_collection_manager_app/app/src/main/assets/cards_initial.db"
DB_DEST="GetDiced/Resources/cards_initial.db"

if [ -f "$DB_SOURCE" ]; then
    mkdir -p GetDiced/Resources
    cp "$DB_SOURCE" "$DB_DEST"
    DB_SIZE=$(du -h "$DB_DEST" | cut -f1)
    echo "   ✓ Copied database file ($DB_SIZE)"
else
    echo "   ⚠️  Database file not found at: $DB_SOURCE"
fi
echo ""

# Step 5: Check for images
echo -e "${BLUE}Step 5: Checking for card images...${NC}"
IMAGE_SOURCE="../srg_card_search_website/backend/app/images/mobile"
if [ -d "$IMAGE_SOURCE" ]; then
    IMAGE_COUNT=$(find "$IMAGE_SOURCE" -name "*.webp" | wc -l | tr -d ' ')
    IMAGE_SIZE=$(du -sh "$IMAGE_SOURCE" | cut -f1)
    echo "   ✓ Found $IMAGE_COUNT card images ($IMAGE_SIZE)"
    echo "   ℹ️  Images will be copied after Xcode project is created"
else
    echo "   ⚠️  Card images not found at: $IMAGE_SOURCE"
fi
echo ""

# Step 6: Check Swift files
echo -e "${BLUE}Step 6: Verifying Swift files...${NC}"
SWIFT_COUNT=$(find GetDiced -name "*.swift" | wc -l | tr -d ' ')
echo "   ✓ Found $SWIFT_COUNT Swift files"
echo ""

# Step 7: Check for iPhone
echo -e "${BLUE}Step 7: Checking for connected devices...${NC}"
if system_profiler SPUSBDataType 2>/dev/null | grep -q "iPhone"; then
    echo "   ✓ iPhone detected"
else
    echo "   ℹ️  No iPhone detected (not required for simulator)"
fi
echo ""

# Summary
echo "========================================"
echo -e "${GREEN}✓ Setup Complete!${NC}"
echo ""
echo "Next steps:"
echo "1. Create Xcode project (see XCODE_PROJECT_SETUP.md)"
echo "2. Import Swift files into Xcode"
echo "3. Add SQLite.swift dependency"
echo "4. Build and run!"
echo ""
echo "For detailed instructions, see: XCODE_PROJECT_SETUP.md"
