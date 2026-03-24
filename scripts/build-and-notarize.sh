#!/bin/bash
set -euo pipefail

SCHEME="RepoRanger (Release)"
APP_NAME="RepoRanger"
KEYCHAIN_PROFILE="notary"

SPARKLE_VERSION="2.9.0"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/build"
SPARKLE_TOOLS_DIR="$PROJECT_DIR/Sparkle-tools"
ARCHIVE_PATH="$BUILD_DIR/$APP_NAME.xcarchive"
EXPORT_DIR="$BUILD_DIR/export"
EXPORT_OPTIONS="$SCRIPT_DIR/ExportOptions.plist"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

if [ ! -x "$SPARKLE_TOOLS_DIR/bin/sign_update" ]; then
    echo "==> Downloading Sparkle tools..."
    SPARKLE_TMP="$BUILD_DIR/Sparkle.tar.xz"
    curl -sL "https://github.com/sparkle-project/Sparkle/releases/download/$SPARKLE_VERSION/Sparkle-$SPARKLE_VERSION.tar.xz" \
        -o "$SPARKLE_TMP"
    mkdir -p "$SPARKLE_TOOLS_DIR"
    tar -xf "$SPARKLE_TMP" -C "$SPARKLE_TOOLS_DIR"
    rm "$SPARKLE_TMP"
    echo "Sparkle tools installed."
fi

VERSION_OVERRIDE=""

echo "==> Checking version against latest GitHub release..."
PROJECT_VERSION=$(xcodebuild -project "$PROJECT_DIR/$APP_NAME.xcodeproj" \
    -scheme "$SCHEME" -showBuildSettings 2>/dev/null \
    | grep 'MARKETING_VERSION' | head -1 | awk '{print $NF}')
echo "Project version: $PROJECT_VERSION"

LATEST=$(gh release view --repo memfrag/RepoRanger --json tagName -q '.tagName' 2>/dev/null || echo "")
if [ -n "$LATEST" ]; then
    LATEST_VER="${LATEST#v}"
    NEWER=$(printf '%s\n' "$LATEST_VER" "$PROJECT_VERSION" | sort -V | tail -1)
    if [ "$NEWER" = "$LATEST_VER" ]; then
        echo "Version $PROJECT_VERSION is not newer than latest release $LATEST."
        printf "Enter new version number: "
        read -r NEW_VERSION
        if [ -z "$NEW_VERSION" ]; then
            echo "No version entered. Aborting."
            exit 1
        fi
        NEWER_CHECK=$(printf '%s\n' "$LATEST_VER" "$NEW_VERSION" | sort -V | tail -1)
        if [ "$NEWER_CHECK" = "$LATEST_VER" ]; then
            echo "ERROR: $NEW_VERSION is not newer than $LATEST. Aborting."
            exit 1
        fi
        echo "==> Updating version in project to $NEW_VERSION..."
        PBXPROJ="$PROJECT_DIR/$APP_NAME.xcodeproj/project.pbxproj"
        sed -i '' "s/MARKETING_VERSION = .*/MARKETING_VERSION = $NEW_VERSION;/g" "$PBXPROJ"
        cd "$PROJECT_DIR"
        git add "$APP_NAME.xcodeproj/project.pbxproj"
        git commit -m "Version $NEW_VERSION"
        git push origin HEAD
        echo "Version updated and committed."
    else
        echo "OK: $PROJECT_VERSION is newer than latest release $LATEST."
    fi
else
    echo "No existing releases found. Proceeding."
fi

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
VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$APP_PATH/Contents/Info.plist")
ZIP_PATH="$BUILD_DIR/$APP_NAME-$VERSION.zip"

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

echo "==> Signing ZIP for Sparkle..."
"$SPARKLE_TOOLS_DIR/bin/sign_update" "$ZIP_PATH"

echo "==> Creating GitHub release..."
printf "Release title ($VERSION: ): "
read -r RELEASE_SUBTITLE
RELEASE_TITLE="$VERSION: $RELEASE_SUBTITLE"
TAG="$VERSION"
cd "$PROJECT_DIR"
git tag "$TAG"
git push origin "$TAG"
gh release create "$TAG" "$ZIP_PATH" \
    --repo memfrag/RepoRanger \
    --title "$RELEASE_TITLE" \
    --generate-notes

echo "==> Done: https://github.com/memfrag/RepoRanger/releases/tag/$TAG"
