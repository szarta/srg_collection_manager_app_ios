#!/bin/bash

echo "🔧 Fixing Xcode Command Line Tools Setup"
echo "=========================================="
echo ""
echo "This will switch xcode-select to use Xcode.app instead of CommandLineTools"
echo "You'll be prompted for your password."
echo ""

sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Successfully switched to Xcode!"
    echo ""
    echo "Current developer directory:"
    xcode-select -p
    echo ""
    echo "Xcode version:"
    xcodebuild -version
else
    echo ""
    echo "❌ Failed to switch. Please check that Xcode is installed at /Applications/Xcode.app"
fi
