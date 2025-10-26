#!/usr/bin/env bash
# Package a modular Python GUI into a signed macOS .app bundle using PyInstaller.
# Usage:
#   scripts/package-macos-app.sh [-n "Friendly Name"] [-e path/to/entry.py] [-i path/to/icon.icns] [-o output/dir]
set -euo pipefail

APP_NAME="Sample Python GUI"
ENTRY_POINT="src/sample_app/__main__.py"
ICON_PATH="build/icon.icns"
DIST_DIR="dist/macos"
WORK_DIR="build/pyinstaller-work"

usage() {
  cat <<'EOF'
Usage: scripts/package-macos-app.sh [options]

Options:
  -n NAME     Display name for the application bundle (default: "Sample Python GUI")
  -e ENTRY    Python entry file to package (default: src/sample_app/__main__.py)
  -i ICON     Path to .icns icon file (default: build/icon.icns)
  -o OUTDIR   Output directory for the .app bundle (default: dist/macos)
  -h          Show this help message

Environment:
  PYINSTALLER_FLAGS   Extra flags appended to the pyinstaller invocation.

The script expects PyInstaller to be installed (pip install -r requirements-dev.txt).
EOF
}

while getopts ":n:e:i:o:h" opt; do
  case "$opt" in
    n) APP_NAME="$OPTARG" ;;
    e) ENTRY_POINT="$OPTARG" ;;
    i) ICON_PATH="$OPTARG" ;;
    o) DIST_DIR="$OPTARG" ;;
    h) usage; exit 0 ;;
    :) echo "Missing value for -$OPTARG" >&2; usage; exit 1 ;;
    \?) echo "Unknown option: -$OPTARG" >&2; usage; exit 1 ;;
  done
done

if ! command -v pyinstaller >/dev/null 2>&1; then
  echo "PyInstaller not found. Install dependencies with: pip install -r requirements-dev.txt" >&2
  exit 1
fi

if [[ ! -f "$ENTRY_POINT" ]]; then
  echo "Entry point '$ENTRY_POINT' not found. Adjust -e flag." >&2
  exit 1
fi

if [[ ! -f "$ICON_PATH" ]]; then
  echo "Icon '$ICON_PATH' not found."
  if [[ -f "build/icon.svg" ]]; then
    echo "You can generate it via: scripts/convert-icons.sh"
  fi
  exit 1
fi

mkdir -p "$DIST_DIR"
mkdir -p "$WORK_DIR"

APP_BUNDLE_NAME="${APP_NAME// /}"
TEMP_DIST="$WORK_DIR/dist"
TEMP_BUILD="$WORK_DIR/build"

rm -rf "$TEMP_DIST" "$TEMP_BUILD" 2>/dev/null || true

echo "Packaging '$APP_NAME' from $ENTRY_POINT ..."
pyinstaller \
  --noconfirm \
  --windowed \
  --name "$APP_BUNDLE_NAME" \
  --icon "$ICON_PATH" \
  --paths src \
  --distpath "$TEMP_DIST" \
  --workpath "$TEMP_BUILD" \
  --specpath "$WORK_DIR" \
  ${PYINSTALLER_FLAGS:-} \
  "$ENTRY_POINT"

APP_SOURCE="$TEMP_DIST/$APP_BUNDLE_NAME.app"
if [[ ! -d "$APP_SOURCE" ]]; then
  echo "PyInstaller did not produce $APP_BUNDLE_NAME.app as expected." >&2
  exit 1
fi

TARGET_APP="$DIST_DIR/$APP_BUNDLE_NAME.app"
echo "Copying bundle to $TARGET_APP"
rm -rf "$TARGET_APP" 2>/dev/null || true
ditto "$APP_SOURCE" "$TARGET_APP"

INFO_PLIST="$TARGET_APP/Contents/Info.plist"
if [[ -f "$INFO_PLIST" ]]; then
  /usr/libexec/PlistBuddy -c "Set :CFBundleName $APP_NAME" "$INFO_PLIST" 2>/dev/null || true
  /usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName $APP_NAME" "$INFO_PLIST" 2>/dev/null || true
  /usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier com.example.$APP_BUNDLE_NAME" "$INFO_PLIST" 2>/dev/null || true
fi

echo "Done. Open '$TARGET_APP' from Finder to test the packaged GUI."
