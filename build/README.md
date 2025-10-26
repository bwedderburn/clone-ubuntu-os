# Icon build helpers

This directory contains a placeholder SVG and cross-platform conversion scripts to generate icon files for the Electron app.

Files included:
- build/icon.svg — placeholder SVG source
- scripts/convert-icons.sh — POSIX shell conversion script
- scripts/convert-icons.ps1 — PowerShell conversion script

How to generate icons locally:
1. Ensure you have Node.js and one of: ImageMagick (magick), Inkscape, or rsvg-convert. On macOS, iconutil is used to make .icns.
2. Run the appropriate script for your OS:
   - macOS / Linux: chmod +x ./scripts/convert-icons.sh && ./scripts/convert-icons.sh
   - Windows (PowerShell): ./scripts/convert-icons.ps1
3. The scripts will generate build/png/icon-*.png and produce build/icon.ico and build/icon.icns (if tools are available).

If you want me to also commit the resulting binaries (PNG/ICO/ICNS), run the scripts locally and paste the generated base64 blobs here or grant me permission to push binaries.
