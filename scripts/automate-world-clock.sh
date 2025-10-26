#!/usr/bin/env bash
set -euo pipefail

# Automate icon generation, Electron packaging, and Git LFS tracking
# Usage:
#   bash ./scripts/automate-world-clock.sh [--push]
# Env:
#   ELECTRON_VERSION: override Electron version (default 38.4.0)
#   PUSH=1           : push after commit

APP_NAME="Multi Time Zone Clock"
ELECTRON_VERSION=${ELECTRON_VERSION:-38.4.0}

# Detect arch mapping for Electron
case "$(uname -m)" in
  arm64) ARCH="arm64" ;;
  x86_64) ARCH="x64" ;;
  *) echo "Unsupported arch: $(uname -m). Set ARCH env to one of x64/arm64." >&2; exit 1 ;;
esac

step(){ echo "[$(date +%H:%M:%S)] $*"; }

step "1/5 Ensure package main entry"
MAIN=$(node -e "try{console.log(require('./package.json').main||'')}catch(e){console.log('')}") || MAIN=""
if [[ "$MAIN" != "main.js" ]]; then
  npm pkg set main=main.js >/dev/null
fi

step "2/5 Generate icons"
bash ./scripts/convert-icons.sh

step "3/5 Package Electron app (darwin/$ARCH, Electron $ELECTRON_VERSION)"
npx --yes @electron/packager . "$APP_NAME" \
  --overwrite --platform=darwin --arch="$ARCH" \
  --icon=build/icon.icns --out dist \
  --electron-version="$ELECTRON_VERSION"

step "4/5 Configure Git LFS and stage artifacts"
(git lfs install >/dev/null 2>&1 || true)
# Track common large artifact patterns
git lfs track "dist/**" "*.asar" "*.dmg" "*.zip" "*.icns" "*.ico" >/dev/null
git add .gitattributes || true
# Force-add dist even if ignored
if [[ -d dist ]]; then
  git add -f dist || true
fi

if ! git diff --cached --quiet; then
  git commit -m "build(world-clock): package app and track dist via LFS (automated)"
else
  step "Nothing to commit"
fi

# Optional push
if [[ "${PUSH:-0}" == "1" || "${1:-}" == "--push" ]]; then
  step "5/5 Pushing to remote"
  git push
else
  step "5/5 Skipping push (pass --push or set PUSH=1)"
fi

step "Done. Output in ./dist"
