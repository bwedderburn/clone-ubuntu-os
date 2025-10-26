# Changelog

## 2.0.0
- Repurpose repository for Python GUI to macOS packaging workflow.
- Add Tkinter sample app under `src/sample_app`.
- Provide PyInstaller-based packaging scripts and refreshed icon pipeline docs.
- Ship default `build/icon.svg` artwork and add dedicated `scripts/package-unified-gui.sh`.
- Remove legacy web/Electron assets.

## 1.0.2
- Auto-detect self-update URL from git remote
- Safer device validation for source/destination
- Run partprobe after partitioning for reliability
- Label new partitions (UBUNTU, STORAGE)
- Fix spinner rotation logic

## 1.0.0
- Initial release with:
  - Multi-drive support
  - Safety checks
  - Spinner & summary table
  - Self-update feature
