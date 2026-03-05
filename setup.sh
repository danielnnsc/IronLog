#!/bin/bash
# IronLog — Xcode project setup script
# Run this on your Mac from the IronLog/ project root.
# Usage: chmod +x setup.sh && ./setup.sh

set -e

echo ""
echo "=== IronLog Setup ==="
echo ""

# Check we're in the right place
if [ ! -f "project.yml" ]; then
  echo "Error: project.yml not found."
  echo "Run this script from the IronLog/ directory (the one containing project.yml)."
  exit 1
fi

# Check for Homebrew
if ! command -v brew &>/dev/null; then
  echo "Homebrew not found. Installing..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Check for XcodeGen
if ! command -v xcodegen &>/dev/null; then
  echo "Installing XcodeGen..."
  brew install xcodegen
else
  echo "XcodeGen already installed: $(xcodegen --version)"
fi

# Generate the project
echo ""
echo "Generating IronLog.xcodeproj..."
xcodegen generate

echo ""
echo "=== Done! ==="
echo ""
echo "Next steps:"
echo "  1. Open IronLog.xcodeproj in Xcode"
echo "  2. Select your Development Team: IronLog target → Signing & Capabilities → Team"
echo "  3. Choose an iPhone simulator (iOS 17+)"
echo "  4. Press Cmd+R to build and run"
echo ""

# Offer to open in Xcode
if [ -d "IronLog.xcodeproj" ]; then
  read -p "Open in Xcode now? (y/n) " -n 1 -r
  echo ""
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    open IronLog.xcodeproj
  fi
fi
