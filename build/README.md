# Icon build helpers

This directory stores source artwork and generated assets for macOS packaging.

Included files:
- `build/icon.svg` — placeholder SVG source (replace with your design).
- `scripts/convert-icons.sh` — POSIX shell conversion script used in the macOS packaging workflow.
- `scripts/convert-icons.ps1` — optional PowerShell alternative.

To regenerate icons:
1. Install one of the supported SVG renderers (`magick`, `inkscape`, or `rsvg-convert`). On macOS the script also relies on `iconutil` for `.icns`.
2. Run the shell script (or PowerShell variant) from the repository root:
   ```bash
   chmod +x scripts/convert-icons.sh
   scripts/convert-icons.sh
   ```
3. PNG icon shards are emitted to `build/png/`, while `build/icon.icns` is used by `scripts/package-macos-app.sh`. Re-run the conversion whenever `icon.svg` changes.
