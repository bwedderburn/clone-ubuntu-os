#!/usr/bin/env bash
# scripts/make-icns.sh
# Generic conversion script that:
# - decodes an existing base64 source if present (the CI workflow handles decoding)
# - creates PNG sizes in build/png/
# - attempts to produce build/icon.icns (prefer native packager on macOS, otherwise uses a Node-based icon maker)
# Usage: ./scripts/make-icns.sh
set -euo pipefail

# Source paths (the workflow decodes the .base64 into these paths)
SRC_PNG="build/source-icon.png"
SRC_SVG="build/source-icon.svg"

PNG_DIR="build/png"
ICONSET_DIR="build/Icon.iconset"
OUT_ICNS="build/icon.icns"
OUT_ICO="build/icon.ico"

mkdir -p "$PNG_DIR"
mkdir -p build

# Choose input: prefer PNG, then SVG
if [[ -f "$SRC_PNG" ]]; then
  SRC="$SRC_PNG"
elif [[ -f "$SRC_SVG" ]]; then
  SRC="$SRC_SVG"
else
  echo "No source icon found at $SRC_PNG or $SRC_SVG. Ensure the workflow decodes a base64 source or add the image locally."
  exit 2
fi

# Sizes we want
sizes=(16 32 48 64 128 256 512 1024)

echo "Generating PNG sizes from $SRC ..."
# The script expects a host environment with an image conversion utility or a Node-based icon maker.
# Provide a conversion command in IMG_CONVERT (e.g. a converter that accepts: input -resize NxN output),
# or provide an SVG-to-PNG command in SVG2PNG if your source is an SVG.
#
# If you have no such commands available in your environment, set the environment variable ICON_MAKER_CMD
# to a command that can take the source and produce an .icns (Node-based tools usually work cross-platform).
#
# Example (local usage): export IMG_CONVERT="magick convert"   # then the script will invoke "$IMG_CONVERT $SRC -resize ${s}x${s} $PNG_DIR/icon-${s}.png"
#
if [[ -n "${IMG_CONVERT:-}" ]]; then
  for s in "${sizes[@]}"; do
    # shellcheck disable=SC2086
    $IMG_CONVERT "$SRC" -resize "${s}x${s}" "$PNG_DIR/icon-${s}.png"
  done
elif [[ -n "${SVG2PNG:-}" && "${SRC##*.}" = "svg" ]]; then
  for s in "${sizes[@]}"; do
    # shellcheck disable=SC2086
    $SVG2PNG -w "$s" -h "$s" "$SRC" -o "$PNG_DIR/icon-${s}.png"
  done
elif [[ -n "${ICON_MAKER_CMD:-}" ]]; then
  echo "No image conversion command supplied; attempting use of ICON_MAKER_CMD to produce icons directly..."
  # ICON_MAKER_CMD is expected to create .icns and/or pngs in build/
  # Example local usage: export ICON_MAKER_CMD="npx electron-icon-maker --input build/source-icon.png --output build --icns --ico"
  eval "$ICON_MAKER_CMD" || true
fi

# If PNGs were created, try to assemble an icon set on macOS (icon packager preferred)
if [[ -d "$PNG_DIR" && -f "$PNG_DIR/icon-1024.png" ]]; then
  if [[ "$(uname -s)" = "Darwin" && -n "${ICONUTIL_CMD:-}" ]]; then
    echo "Creating Icon.iconset and building .icns using ICONUTIL_CMD..."
    rm -rf "$ICONSET_DIR"
    mkdir -p "$ICONSET_DIR"
    cp "$PNG_DIR/icon-16.png"  "$ICONSET_DIR/icon_16x16.png"   || true
    cp "$PNG_DIR/icon-32.png"  "$ICONSET_DIR/icon_16x16@2x.png"|| true
    cp "$PNG_DIR/icon-32.png"  "$ICONSET_DIR/icon_32x32.png"   || true
    cp "$PNG_DIR/icon-64.png"  "$ICONSET_DIR/icon_32x32@2x.png"|| true
    cp "$PNG_DIR/icon-128.png" "$ICONSET_DIR/icon_128x128.png" || true
    cp "$PNG_DIR/icon-256.png" "$ICONSET_DIR/icon_128x128@2x.png" || true
    cp "$PNG_DIR/icon-256.png" "$ICONSET_DIR/icon_256x256.png" || true
    cp "$PNG_DIR/icon-512.png" "$ICONSET_DIR/icon_256x256@2x.png" || true
    cp "$PNG_DIR/icon-512.png" "$ICONSET_DIR/icon_512x512.png" || true
    cp "$PNG_DIR/icon-1024.png" "$ICONSET_DIR/icon_512x512@2x.png" || true
    # shellcheck disable=SC2086
    $ICONUTIL_CMD -c icns "$ICONSET_DIR" -o "$OUT_ICNS" || true
    echo "Created $OUT_ICNS (if icon packager succeeded)."
  else
    # fallback: if ICON_MAKER_CMD produced .icns, we are done; otherwise attempt ICON_MAKER_CMD now
    if [[ -n "${ICON_MAKER_CMD:-}" ]]; then
      echo "Attempting ICON_MAKER_CMD fallback to generate .icns..."
      eval "$ICON_MAKER_CMD" || true
    else
      echo "No icon packager available in environment to assemble .icns. Provide ICON_MAKER_CMD or run on macOS with a packager."
    fi
  fi
else
  echo "PNG generation may have failed; check the environment or provide conversion commands via IMG_CONVERT / SVG2PNG / ICON_MAKER_CMD."
fi

echo "Done. Files in build/:"
ls -la build || true
ls -la build/png || true