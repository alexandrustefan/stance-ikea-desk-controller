#!/usr/bin/env bash
# Build Release Stance.app and copy it to /Applications.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

CONFIGURATION="${CONFIGURATION:-Release}"
DERIVED_DATA="${DERIVED_DATA:-build/DerivedData}"
DEST="${INSTALL_PATH:-/Applications/Stance.app}"
APP="$DERIVED_DATA/Build/Products/$CONFIGURATION/Stance.app"

echo "→ Generating Xcode project…"
xcodegen generate

BUILD_ARGS=(
  build
  -project IKEADeskController.xcodeproj
  -scheme IKEADeskController
  -configuration "$CONFIGURATION"
  -derivedDataPath "$DERIVED_DATA"
)

if [[ -n "${DEVELOPMENT_TEAM:-}" ]]; then
  BUILD_ARGS+=(
    DEVELOPMENT_TEAM="$DEVELOPMENT_TEAM"
    CODE_SIGN_STYLE=Automatic
  )
  echo "→ Building $CONFIGURATION with team $DEVELOPMENT_TEAM…"
else
  BUILD_ARGS+=(
    CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY:--}"
    CODE_SIGNING_REQUIRED="${CODE_SIGNING_REQUIRED:-NO}"
  )
  echo "→ Building $CONFIGURATION (ad-hoc signing)…"
  echo "  Tip: set Signing → Team in Xcode, or run DEVELOPMENT_TEAM=XXXXXXXX ./Scripts/install.sh"
  echo "  so Bluetooth permission persists between launches."
fi

xcodebuild "${BUILD_ARGS[@]}"

if [[ ! -d "$APP" ]]; then
  echo "error: expected app at $APP" >&2
  exit 1
fi

if [[ -d "$DEST" ]]; then
  echo "→ Replacing existing install at $DEST…"
  rm -rf "$DEST"
fi

echo "→ Installing to $DEST…"
cp -R "$APP" "$DEST"

echo ""
echo "Installed Stance."
echo "  Open: open -a Stance"
echo "  Or launch from Applications / Spotlight."
if [[ -z "${DEVELOPMENT_TEAM:-}" ]]; then
  echo ""
  echo "Note: this build is ad-hoc signed. macOS may ask for Bluetooth on every launch."
  echo "Sign with your Apple ID team in Xcode for a one-time permission grant."
fi
