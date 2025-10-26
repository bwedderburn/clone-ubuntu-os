````markdown
# make-icns helper

This repository file set automates turning a source image into macOS icon assets.

How it works
- Place your source image (PNG or SVG) at `build/source-icon.png` (or `build/source-icon.svg`).
- The `scripts/make-icns.sh` script creates `build/png/icon-*.png` and `build/icon.icns`.
- The GitHub Action `.github/workflows/make-icns.yml` runs the script on pushes to branch `add/icons` (or manually via workflow_dispatch) and commits the generated assets back to the branch.

Recommended flow
1. Add the source image:
   - Locally: `git checkout add/icons && cp path/to/your-image.png build/source-icon.png && git add build/source-icon.png && git commit -m "chore(icon): add source icon" && git push origin add/icons`
   - Or paste a base64 blob in the chat and I will decode & commit for you if you want me to.

2. Run locally:
   - `chmod +x ./scripts/make-icns.sh`
   - `./scripts/make-icns.sh`
   - Check `build/icon.icns` and `build/png/`

3. Or let CI do it:
   - Push the branch `add/icons` with `build/source-icon.png` present.
   - The workflow will run and commit generated artifacts back into the branch.

Notes
- On macOS the script prefers `iconutil` (native) to create the best .icns.
- On non-mac hosts the script uses `npx electron-icon-maker` as a fallback to produce an .icns.
- Make sure `build/source-icon.png` is a square image (1024×1024 recommended) for best results.