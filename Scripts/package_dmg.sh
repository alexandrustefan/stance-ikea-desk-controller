#!/usr/bin/env bash
# Package Stance.app into a drag-to-Applications DMG.
set -euo pipefail

VERSION="${1:?Usage: package_dmg.sh VERSION [path/to/Stance.app]}"
APP_PATH="${2:-build/DerivedData/Build/Products/Release/Stance.app}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
STAGING="$ROOT/build/dmg-staging"
DMG="$ROOT/build/Stance-${VERSION}.dmg"

if [[ ! -d "$APP_PATH" ]]; then
  echo "error: app not found at $APP_PATH" >&2
  exit 1
fi

rm -rf "$STAGING"
mkdir -p "$STAGING"
cp -R "$APP_PATH" "$STAGING/Stance.app"
ln -sf /Applications "$STAGING/Applications"

rm -f "$DMG"
hdiutil create \
  -volname "Stance ${VERSION}" \
  -srcfolder "$STAGING" \
  -ov \
  -format UDZO \
  "$DMG"

echo "Created $DMG"
