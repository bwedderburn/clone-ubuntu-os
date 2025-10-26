#!/usr/bin/env bash
# POSIX shell script to convert build/icon.svg -> PNG set, icon.ico, icon.icns
# Usage: ./scripts/convert-icons.sh
set -euo pipefail

SVG="build/icon.svg"
PNG_DIR="build/png"
ICONSET_DIR="build/Icon.iconset"
OUT_ICNS="build/icon.icns"
OUT_ICO="build/icon.ico"

mkdir -p "$PNG_DIR"
mkdir -p build

# Sizes we commonly need
sizes=(16 32 48 64 128 256 512 1024)

echo "Generating PNGs from $SVG ..."
if command -v magick >/dev/null 2>&1; then
  for s in "${sizes[@]}"; do
    magick convert "$SVG" -resize "${s}x${s}" "$PNG_DIR/icon-${s}.png"
  done
elif command -v inkscape >/dev/null 2>&1; then
  for s in "${sizes[@]}"; do
    inkscape "$SVG" --export-filename="$PNG_DIR/icon-${s}.png" --export-width="$s" --export-height="$s"
  done
elif command -v rsvg-convert >/dev/null 2>&1; then
  for s in "${sizes[@]}"; do
    rsvg-convert -w "$s" -h "$s" "$SVG" -o "$PNG_DIR/icon-${s}.png"
  done
else
  echo "No SVG -> PNG converter found (magick / inkscape / rsvg-convert). Install one or use the electron-icon-maker fallback."
fi

# Create .ico (Windows)
echo "Building $OUT_ICO ..."
if command -v png2ico >/dev/null 2>&1; then
  png2ico "$OUT_ICO" "$PNG_DIR/icon-16.png" "$PNG_DIR/icon-32.png" "$PNG_DIR/icon-48.png" "$PNG_DIR/icon-64.png" "$PNG_DIR/icon-128.png" "$PNG_DIR/icon-256.png"
elif command -v magick >/dev/null 2>&1; then
  magick convert "$PNG_DIR/icon-16.png" "$PNG_DIR/icon-32.png" "$PNG_DIR/icon-48.png" "$PNG_DIR/icon-64.png" "$PNG_DIR/icon-128.png" "$PNG_DIR/icon-256.png" "$OUT_ICO"
else
  echo "png2ico or ImageMagick (magick) not found. Will try electron-icon-maker fallback."
fi

# Create .icns (macOS)
if [[ "
" = "Darwin" ]]; then
  echo "Building $OUT_ICNS using iconutil (macOS) ..."
  rm -rf "$ICONSET_DIR"
  mkdir -p "$ICONSET_DIR"
  # Map PNGs into iconset names
  cp "$PNG_DIR/icon-16.png"  "$ICONSET_DIR/icon_16x16.png"
  cp "$PNG_DIR/icon-32.png"  "$ICONSET_DIR/icon_16x16@2x.png"
  cp "$PNG_DIR/icon-32.png"  "$ICONSET_DIR/icon_32x32.png"
  cp "$PNG_DIR/icon-64.png"  "$ICONSET_DIR/icon_32x32@2x.png"
  cp "$PNG_DIR/icon-128.png" "$ICONSET_DIR/icon_128x128.png"
  cp "$PNG_DIR/icon-256.png" "$ICONSET_DIR/icon_128x128@2x.png"
  cp "$PNG_DIR/icon-256.png" "$ICONSET_DIR/icon_256x256.png"
  cp "$PNG_DIR/icon-512.png" "$ICONSET_DIR/icon_256x256@2x.png"
  cp "$PNG_DIR/icon-512.png" "$ICONSET_DIR/icon_512x512.png"
  cp "$PNG_DIR/icon-1024.png" "$ICONSET_DIR/icon_512x512@2x.png"
  iconutil -c icns "$ICONSET_DIR" -o "$OUT_ICNS"
else
  echo "Not macOS or iconutil not available. Skipping iconutil step for ICNS."
fi

# electron-icon-maker fallback (cross-platform). This requires Node.js and internet access for npx.
if command -v npx >/dev/null 2>&1; then
  echo "Running npx electron-icon-maker fallback (creates icns + ico in build/) ..."
  if [[ -f "$PNG_DIR/icon-1024.png" ]]; then
    npx --yes electron-icon-maker --input "$PNG_DIR/icon-1024.png" --output build --icns --ico || true
  elif [[ -f "$SVG" ]]; then
    npx --yes electron-icon-maker --input "$SVG" --output build --icns --ico || true
  fi
else
  echo "npx not present; cannot run electron-icon-maker fallback. Install Node.js or run conversion manually."
fi

echo "Conversion complete. Outputs (if created):"
ls -l build/icon.* build/png/* 2>/dev/null || true
