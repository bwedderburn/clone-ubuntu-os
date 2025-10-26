# Repository Guidelines

## Project Structure & Module Organization
- Keep Python GUI packages under `src/`, mirroring the sample `src/sample_app/` layout with clear module boundaries (`__main__.py` for entry, additional widgets in separate files).
- Icon source assets live in `build/`; always treat the SVG as the source of truth and regenerate PNG/ICNS outputs using the provided scripts.
- Packaged `.app` bundles should land in `dist/macos/`. Do not modify contents in place—rerun the packaging script when code or assets change.
- Shared automation, packaging, and helper utilities belong in `scripts/`; prefer descriptive kebab-case filenames (`package-macos-app.sh`) and document usage with inline comments.

## Build, Test, and Development Commands
- `python -m venv .venv && source .venv/bin/activate` to isolate dependencies before installs.
- `pip install -r requirements-dev.txt` brings in PyInstaller; add your GUI deps afterwards.
- `scripts/convert-icons.sh` re-renders raster assets and `build/icon.icns` from `build/icon.svg`.
- `scripts/package-macos-app.sh -n "My GUI" -e src/my_app/__main__.py -i build/icon.icns` generates a macOS bundle in `dist/macos/`.
- `open dist/macos/MyGUI.app` launches the packaged build for a smoke test.

## Coding Style & Naming Conventions
- Python modules follow PEP 8 with 4-space indentation; keep GUI construction code modular (separate widget classes, avoid giant functions).
- Use explicit `if __name__ == "__main__":` guards in runnable modules; expose helper factories (see `build_app()` in `sample_app/gui.py`) for reuse.
- Shell scripts should be Bash with `set -euo pipefail`, lowercase variables, and functions for reusable logic. Document non-obvious behavior in concise comments.
- Place assets, entry points, and scripts in predictable directories so packaging flags (`--paths`, `--add-data`) stay consistent.

## Testing Guidelines
- Manual verification is required: run the package with `python -m sample_app` during development, then open the `.app` bundle to confirm resources, icon, and GUI behavior.
- When changing icon tooling, inspect every generated size in `build/png/` and ensure the `.icns` updates (Quick Look the bundle to verify).
- After PyInstaller tweaks, watch the terminal output for missing modules/warnings and review the `.app/Contents/Resources` tree for expected assets.

## Commit & Pull Request Guidelines
- Use imperative, scoped commits (e.g., `build: update macOS packager script`, `docs: expand icon workflow`). One logical change per commit keeps reviews focused.
- Regenerate icons or bundles within the same commit that changes their sources; avoid committing transient `build/pyinstaller-work` files.
- PRs should call out GUI frameworks touched, include manual test notes (module run + packaged run), and attach screenshots or screen recordings for UI visible changes.
