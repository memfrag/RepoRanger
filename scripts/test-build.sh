#!/bin/bash
set -euo pipefail

SCHEME="RepoRanger (Release)"
APP_NAME="RepoRanger"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/build"
ARCHIVE_PATH="$BUILD_DIR/test.xcarchive"
EXPORT_DIR="$BUILD_DIR/test-export"
EXPORT_OPTIONS="$SCRIPT_DIR/ExportOptions.plist"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

echo "==> Archiving..."
xcodebuild archive \
    -project "$PROJECT_DIR/$APP_NAME.xcodeproj" \
    -scheme "$SCHEME" \
    -archivePath "$ARCHIVE_PATH" \
    -configuration Release \
    -arch arm64 \
    ENABLE_HARDENED_RUNTIME=YES \
    | tail -1

echo "==> Exporting..."
xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_DIR" \
    -exportOptionsPlist "$EXPORT_OPTIONS" \
    | tail -1

APP_PATH="$EXPORT_DIR/$APP_NAME.app"

echo "==> Verifying codesign..."
codesign --verify --deep --strict "$APP_PATH" 2>&1
echo "Codesign OK."

echo "==> Checking framework contents..."
ls -la "$APP_PATH/Contents/Frameworks/Sparkle.framework/"
echo ""
ls -la "$APP_PATH/Contents/XPCServices/" 2>/dev/null || echo "No XPCServices directory in app bundle."
