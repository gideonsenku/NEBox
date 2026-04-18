#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCHEME="RelayMac"
APP_NAME="Relay"
BUILD_DIR="build"
DERIVED_DIR="$BUILD_DIR/derived"
STAGING_DIR="$BUILD_DIR/dmg-staging"
APP_PATH="$DERIVED_DIR/Build/Products/Release/$APP_NAME.app"
DMG_PATH="$BUILD_DIR/$APP_NAME.dmg"

rm -rf "$STAGING_DIR" "$DMG_PATH"
mkdir -p "$BUILD_DIR"

xcodebuild \
  -project Relay.xcodeproj \
  -scheme "$SCHEME" \
  -configuration Release \
  -derivedDataPath "$DERIVED_DIR" \
  -destination 'generic/platform=macOS' \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGN_STYLE=Automatic \
  DEVELOPMENT_TEAM="" \
  build

mkdir -p "$STAGING_DIR"
cp -R "$APP_PATH" "$STAGING_DIR/"
ln -s /Applications "$STAGING_DIR/Applications"

hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$STAGING_DIR" \
  -ov -format UDZO \
  "$DMG_PATH"

rm -rf "$STAGING_DIR"

echo ""
echo "✅ DMG built: $DMG_PATH"
ls -lh "$DMG_PATH"
