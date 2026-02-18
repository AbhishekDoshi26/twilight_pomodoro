#!/bin/bash

# Exit on any error
set -e

echo "🚀 Starting Twilight Pomodoro macOS Build Process..."

# 0. Initial Cleanup
echo "🧹 Cleaning up existing distribution files..."
ROOT_DIR=$(pwd)
APP_NAME="Twilight Pomodoro"

# Remove any old ZIP files starting with Twilight_Pomodoro_macOS
rm -f "Twilight_Pomodoro_macOS"*".zip"

# 1. Automatic Version Increment
echo "🔢 Incrementing Build Number..."
VERSION_LINE=$(grep "^version: " pubspec.yaml)
VERSION_STR=$(echo $VERSION_LINE | cut -d ' ' -f 2)
VERSION_NAME=$(echo $VERSION_STR | cut -d '+' -f 1)
BUILD_NUMBER=$(echo $VERSION_STR | cut -d '+' -f 2)

# Increment build number
NEW_BUILD_NUMBER=$((BUILD_NUMBER + 1))
NEW_VERSION="$VERSION_NAME+$NEW_BUILD_NUMBER"

# Update pubspec.yaml using sed (macOS version)
sed -i '' "s/^version: .*/version: $NEW_VERSION/" pubspec.yaml

echo "🏷️  Old Version: $VERSION_STR"
echo "✨ New Version: $NEW_VERSION"

# 2. Clean and Get Dependencies
echo "🧹 Cleaning project..."
flutter clean

echo "📦 Fetching Flutter dependencies..."
flutter pub get

# 3. Native macOS Setup
echo "🛠️ Installing CocoaPods..."
cd macos
pod install
cd ..

# 4. Build Release Version
echo "🏗️ Building macOS Release..."
flutter build macos --release

# 5. Prepare for Distribution
BUILD_DIR="build/macos/Build/Products/Release"
ZIP_NAME="Twilight_Pomodoro_macOS_v${VERSION_NAME}_b${NEW_BUILD_NUMBER}.zip"

if [ -d "$BUILD_DIR/$APP_NAME.app" ]; then
    echo "✅ Build Successful!"
    
    # Zip directly from the build directory to the root
    echo "🤐 Creating versioned ZIP archive..."
    cd "$BUILD_DIR"
    zip -r "$ROOT_DIR/$ZIP_NAME" "$APP_NAME.app"
    cd "$ROOT_DIR"
    
    # Update README link to the specific versioned ZIP
    echo "📝 Updating README with new download link..."
    sed -i '' "s/Twilight_Pomodoro_macOS.*\.zip/$ZIP_NAME/g" README.md
    
    echo "------------------------------------------------"
    echo "✨ Process Complete!"
    echo "📦 New App Version: $NEW_VERSION"
    echo "📂 Distributable: $ZIP_NAME"
    echo "📝 README updated with specific version link."
    echo "------------------------------------------------"
else
    echo "❌ Error: Build output not found at $BUILD_DIR/$APP_NAME.app"
    exit 1
fi
