#!/usr/bin/env bash
# Package the amp-benchkit Unified GUI (Lite+U3) into a macOS .app bundle.
# Usage:
#   scripts/package-unified-gui.sh [--name "Unified Control Lite+U3"] [--icon build/icon.icns]
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

APP_NAME="Unified Control Lite+U3"
APP_BUNDLE_ID="com.labtools.unifiedgui"
ENTRY_POINT="$REPO_ROOT/../amp-benchkit/unified_gui_layout.py"
ICON_PATH="$REPO_ROOT/build/icon.icns"
DIST_DIR="$REPO_ROOT/dist/unified-gui"
WORK_ROOT="$REPO_ROOT/build/pyinstaller-work/unified-gui"

usage() {
  cat <<'EOF'
Usage: scripts/package-unified-gui.sh [options]

Options:
  --name NAME     Displayed bundle name (default: "Unified Control Lite+U3")
  --icon PATH     Path to .icns file (default: build/icon.icns)
  -h, --help      Show this help message

Environment:
  PYINSTALLER_FLAGS  Extra flags appended to the PyInstaller invocation.

Prereqs:
  - Install runtime deps: pip install -r ../amp-benchkit/requirements.txt
  - Install PyInstaller: pip install -r requirements-dev.txt
  - Generate icons: scripts/convert-icons.sh (ensures build/icon.icns exists)
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --name)
      APP_NAME="$2"
      shift 2
      ;;
    --icon)
      ICON_PATH="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if ! command -v pyinstaller >/dev/null 2>&1; then
  echo "PyInstaller not found. Install with: pip install -r requirements-dev.txt" >&2
  exit 1
fi

if [[ ! -f "$ENTRY_POINT" ]]; then
  echo "Entry point not found at $ENTRY_POINT." >&2
  echo "Clone amp-benchkit adjacent to this repo or adjust the script." >&2
  exit 1
fi

if [[ ! -f "$ICON_PATH" ]]; then
  echo "Icon '$ICON_PATH' is missing. Run scripts/convert-icons.sh after updating build/icon.svg." >&2
  exit 1
fi

mkdir -p "$DIST_DIR"
mkdir -p "$WORK_ROOT"

APP_BUNDLE_NAME="$(echo "$APP_NAME" | tr -cd '[:alnum:]')"
if [[ -z "$APP_BUNDLE_NAME" ]]; then
  APP_BUNDLE_NAME="UnifiedGui"
fi
TEMP_DIST="$WORK_ROOT/dist"
TEMP_BUILD="$WORK_ROOT/build"

rm -rf "$TEMP_DIST" "$TEMP_BUILD" "$WORK_ROOT"/*.spec 2>/dev/null || true

echo "Packaging '$APP_NAME' from $ENTRY_POINT ..."
PYI_ARGS=(
  --noconfirm
  --windowed
  --name "$APP_BUNDLE_NAME"
  --icon "$ICON_PATH"
  --distpath "$TEMP_DIST"
  --workpath "$TEMP_BUILD"
  --specpath "$WORK_ROOT"
  --paths "$REPO_ROOT/src"
  --paths "$REPO_ROOT/../amp-benchkit"
  --collect-data amp_benchkit
)

if [[ -n "${PYINSTALLER_FLAGS:-}" ]]; then
  # shellcheck disable=SC2206
  EXTRA_FLAGS=(${PYINSTALLER_FLAGS})
  PYI_ARGS+=("${EXTRA_FLAGS[@]}")
fi

pyinstaller "${PYI_ARGS[@]}" "$ENTRY_POINT"

APP_SOURCE="$TEMP_DIST/$APP_BUNDLE_NAME.app"
if [[ ! -d "$APP_SOURCE" ]]; then
  echo "PyInstaller did not create $APP_BUNDLE_NAME.app" >&2
  exit 1
fi

TARGET_APP="$DIST_DIR/$APP_NAME.app"
echo "Copying bundle to $TARGET_APP"
rm -rf "$TARGET_APP" 2>/dev/null || true
ditto "$APP_SOURCE" "$TARGET_APP"

INFO_PLIST="$TARGET_APP/Contents/Info.plist"
if [[ -f "$INFO_PLIST" ]]; then
  /usr/libexec/PlistBuddy -c "Set :CFBundleName $APP_NAME" "$INFO_PLIST" 2>/dev/null || true
  /usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName $APP_NAME" "$INFO_PLIST" 2>/dev/null || true
  /usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $APP_BUNDLE_ID" "$INFO_PLIST" 2>/dev/null || true
fi

echo "Done. Open '$TARGET_APP' to verify the packaged Unified GUI."
