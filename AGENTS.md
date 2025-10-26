# Repository Guidelines

## Project Structure & Module Organization
- Keep Python GUI sources under `src/` for local demos; the production target lives in the sibling repo `../amp-benchkit` (entry: `unified_gui_layout.py`).
- Icon source assets live in `build/`; treat `build/icon.svg` as the only editable artifact and regenerate PNG/ICNS outputs via the scripts.
- macOS bundles for generic demos go to `dist/macos/`; the amp-benchkit build writes to `dist/unified-gui/`. Never edit bundle contents manually—rerun the relevant packaging script.
- Shared automation and helpers belong in `scripts/`; maintain descriptive kebab-case filenames (`package-unified-gui.sh`) and keep inline comments brief but informative.

## Build, Test, and Development Commands
- `python -m venv .venv && source .venv/bin/activate` to isolate dependencies before installs.
- `pip install -r requirements-dev.txt` brings in PyInstaller; follow with GUI-specific deps (`pip install -r ../amp-benchkit/requirements.txt && pip install -e ../amp-benchkit` for the Unified GUI).
- `scripts/convert-icons.sh` re-renders raster assets and `build/icon.icns` from `build/icon.svg`.
- `scripts/package-macos-app.sh -n "My GUI" -e src/my_app/__main__.py -i build/icon.icns` targets custom/local demos.
- `scripts/package-unified-gui.sh` packages the amp-benchkit Unified GUI into `dist/unified-gui/Unified Control Lite+U3.app`.
- `open dist/macos/MyGUI.app` or `open "dist/unified-gui/Unified Control Lite+U3.app"` launches bundles for smoke tests.

## Coding Style & Naming Conventions
- Python modules follow PEP 8 with 4-space indentation; keep GUI construction code modular (separate widget classes, avoid giant functions).
- Use explicit `if __name__ == "__main__":` guards in runnable modules; expose helper factories (see `build_app()` in `sample_app/gui.py`) for reuse.
- Shell scripts should be Bash with `set -euo pipefail`, lowercase variables, and functions for reusable logic. Document non-obvious behavior in concise comments.
- Place assets, entry points, and scripts in predictable directories so packaging flags (`--paths`, `--add-data`) stay consistent.

## Testing Guidelines
- Manual verification is required: run the module directly (`PYTHONPATH=../amp-benchkit python ../amp-benchkit/unified_gui_layout.py --gui` or `python -m sample_app`) and then open the packaged `.app` bundle to confirm resources, icon, and GUI behavior.
- When changing icon tooling, inspect every generated size in `build/png/` and ensure the `.icns` updates (Quick Look the bundle to verify).
- After PyInstaller tweaks, watch the terminal output for missing modules/warnings and review the `.app/Contents/Resources` tree for expected assets (especially `amp_benchkit/calibration_data`).

## Commit & Pull Request Guidelines
- Use imperative, scoped commits (e.g., `build: update macOS packager script`, `docs: expand icon workflow`). One logical change per commit keeps reviews focused.
- Regenerate icons or bundles within the same commit that changes their sources; avoid committing transient `build/pyinstaller-work` files or `dist` outputs (they're reproducible).
- PRs should call out GUI frameworks touched, include manual test notes (module run + packaged run), and attach screenshots or screen recordings for UI visible changes.
