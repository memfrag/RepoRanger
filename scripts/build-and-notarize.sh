#!/bin/bash
set -euo pipefail

SCHEME="RepoRanger (Release)"
APP_NAME="RepoRanger"
KEYCHAIN_PROFILE="notary"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/build"
ARCHIVE_PATH="$BUILD_DIR/$APP_NAME.xcarchive"
EXPORT_DIR="$BUILD_DIR/export"
EXPORT_OPTIONS="$SCRIPT_DIR/ExportOptions.plist"
ZIP_PATH="$BUILD_DIR/$APP_NAME.zip"

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
codesign --verify --deep --strict "$APP_PATH"
echo "Codesign OK."

echo "==> Zipping for notarization..."
NOTARIZE_ZIP="$BUILD_DIR/$APP_NAME-notarize.zip"
ditto -c -k --keepParent "$APP_PATH" "$NOTARIZE_ZIP"

echo "==> Submitting for notarization..."
xcrun notarytool submit "$NOTARIZE_ZIP" \
    --keychain-profile "$KEYCHAIN_PROFILE" \
    --wait || { echo "Notarization failed. Run: xcrun notarytool log <submission-id> --keychain-profile $KEYCHAIN_PROFILE"; exit 1; }

rm "$NOTARIZE_ZIP"

echo "==> Stapling..."
xcrun stapler staple "$APP_PATH"

echo "==> Packaging ZIP..."
ditto -c -k --keepParent "$APP_PATH" "$ZIP_PATH"

echo "==> Done: $ZIP_PATH"
