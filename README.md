# Python macOS App Packager

This repository packages a modularised Python GUI into a standalone macOS `.app` bundle with a custom icon. It ships with a small Tkinter demo under `src/sample_app` so you can verify the workflow locally, then swap in your own package structure.

## Prerequisites
- macOS with Xcode command line tools (for `iconutil`, `ditto`, `PlistBuddy`)
- Python 3.9+ and a virtual environment for your GUI project
- PyInstaller (`pip install -r requirements-dev.txt`)
- An SVG source icon at `build/icon.svg` (replace the sample art)

## Workflow Overview
1. **Activate your venv** and install PyInstaller plus your GUI dependencies.
2. **Prepare icons** – replace `build/icon.svg` with your art, then run:
   ```bash
   scripts/convert-icons.sh
   ```
   This renders PNGs, a `.ico` (optional) and `build/icon.icns`.
3. **Smoke-test the Python package directly** during development:
   ```bash
   PYTHONPATH=src python -m sample_app
   ```
   Swap `sample_app` for your package name to confirm the GUI launches before bundling.
4. **Point the packaging script at your entry module:**
   ```bash
   scripts/package-macos-app.sh \
     -n "My GUI" \
     -e src/sample_app/__main__.py \
     -i build/icon.icns
 ```
  Update `-e` to match your package’s main script. The bundle lands in `dist/macos/`.
5. **Smoke-test** the generated `*.app` directly from Finder or via:
  ```bash
  open dist/macos/MyGUI.app
  ```

## Bundling the amp-benchkit Unified GUI
This repository is pre-configured to turn the `unified_gui_layout.py` application from the adjacent `amp-benchkit` project into a macOS app bundle.

1. Clone the GUI source next to this repo (already present in `../amp-benchkit`).
2. Create and activate a virtual environment, then install dependencies:
   ```bash
   python -m venv .venv
   source .venv/bin/activate
   pip install -r requirements-dev.txt
   pip install -r ../amp-benchkit/requirements.txt
   pip install -e ../amp-benchkit
   ```
3. Update the branding in `build/icon.svg` if desired and regenerate assets:
   ```bash
   scripts/convert-icons.sh
   ```
4. Package the GUI:
   ```bash
   scripts/package-unified-gui.sh
   ```
   Pass extra PyInstaller switches via `PYINSTALLER_FLAGS` (e.g. `--hidden-import` entries) if you need to tweak the build.
5. Launch the bundle for verification:
   ```bash
   open "dist/unified-gui/Unified Control Lite+U3.app"
   ```

You can still run the Python sources directly for debugging:
```bash
PYTHONPATH=../amp-benchkit python ../amp-benchkit/unified_gui_layout.py --gui
```

## Project Layout
- `src/sample_app/` – Minimal Tkinter clock demonstrating a package-style GUI.
- `scripts/convert-icons.sh` – Converts `build/icon.svg` into PNG shards and `.icns`.
- `scripts/package-macos-app.sh` – Wraps PyInstaller with sensible defaults for custom apps.
- `scripts/package-unified-gui.sh` – Turn `../amp-benchkit/unified_gui_layout.py` into a macOS bundle.
- `build/` – Icon sources and generated assets (safe to regenerate).
- `dist/macos/` – Output directory for packaged `.app` bundles.

## Adapting to Your GUI
- Keep your Python modules under `src/` and expose an entry file that spins up the GUI event loop.
- Pass `--paths` flags via `PYINSTALLER_FLAGS` if you need extra search paths or data hooks:
  ```bash
  PYINSTALLER_FLAGS="--add-data resources:resources" scripts/package-macos-app.sh -e src/my_app/main.py
  ```
- To reuse the amp-benchkit packaging script with another entry point, call `scripts/package-macos-app.sh` and add `-p` flags for every additional source directory that PyInstaller should index.
- Signing and notarisation are out of scope; run Apple’s `codesign` and `notarytool` afterwards if you plan to distribute beyond local machines.

## License
MIT – adapt and extend for your own packaging workflows.
