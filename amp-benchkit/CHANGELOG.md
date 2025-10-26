Changelog
=========

All notable changes to this project will be documented in this file.
The format is Keep a Changelog, and this project adheres to Semantic Versioning (SemVer)
starting with 0.x pre-release phases.

[Unreleased]
------------

### Added

- Enhanced FFT capture with vertical scale and position controls for TDS 2024B oscilloscope
  - `scope_capture_fft_trace()` now accepts `vertical_scale` and `vertical_position` parameters
  - New `scope_read_fft_vertical_params()` function to query current FFT vertical settings
  - Example script `scripts/example_fft_capture.py` demonstrating proper FFT scaling usage
  - Comprehensive test suite for tek module (11 new tests in `tests/test_tek.py`)
  - Documentation updates in `docs/hardware-setup.md` with FFT best practices

### Changed

- Added `knee-sweep` CLI support for -3 dB bandwidth detection with smoothing/monotonic controls, gold calibration, CSV export, and accompanying tests/docs.
- New `fft-capture` CLI subcommand configures the Tek math FFT trace, exports frequency/amplitude CSV data, and reports the strongest bins (with optional FY retune helper).
- Added `scripts/fft_thd_compare.py` for offline comparison between THD sweep CSVs and FFT captures (auto-detected fundamental, harmonic windowing, and delta reporting).
- Introduced `fft-sweep` CLI for timestamped FFT captures across a frequency list, including automatic FY retune and optional FFT span/zoom configuration.
- Added `scripts/run_thd_sweep.py` to auto-detect Tek/FY hardware, apply scope auto-scaling/calibration, and produce timestamped THD sweep datasets.
- Updated `ruff.toml` to allow E402 (module-level imports) in scripts directory

[0.3.9] - 2025-10-12
--------------------

**Added**

- Automatic Tektronix vertical scaling for THD sweeps via new CLI options (`--scope-auto-scale`, `--scope-auto-scale-margin`, `--scope-auto-scale-min`, `--scope-auto-scale-divs`), including logging and tests around the post-sweep generator reset.
- Gold-calibrated baseline assets for 0.2–0.5 Vpp Kenwood KAC-823 sweeps, plus helper plots comparing raw vs calibrated THD/Vrms.

**Changed**

- Added a `Documentation` URL to the package metadata pointing to the GitHub Pages site.
- README and docs now explain how to enable auto-scaling and archive sweep artefacts for repeatable amplifier sessions.

[0.3.7] - 2025-10-11
--------------------

**Added**

- MkDocs documentation site with a dedicated GitHub Pages workflow and `docs` optional extra for local previews.
- Richer diagnostics tooling: new `amp_benchkit.diagnostics` collector, UI toggles, and save/copy/clear actions that log snapshots under `results/diagnostics/`.

**Changed**

- Default FY generator amplitude (GUI, automation, and CLI fallback) now starts at 0.25 Vpp to avoid clipping during bring-up.
- CLI `diag` subcommand and GUI diagnostics output both reuse the structured collector for consistent reporting.

**Fixed**

- Suppressed spurious `LIBUSB_ERROR_NOT_FOUND` warnings when opening LabJack U3 hardware.
- Restored IEEE block passthrough behaviour so the self-test suite and raw captures handle non-`#` payloads correctly.

[0.3.6] - 2025-10-07
--------------------

**Fixed**

- `sweep_audio_kpis` now routes channel/mathematics captures through `scope_capture_calibrated` using an explicit `ch` parameter, fixing Tektronix math/differential sweeps.
- Tek scope utilities normalise channel names (including `MATH`) and guard timeout parsing so GUI/automation captures no longer fall back to CH1 or raise `ValueError`.

[0.3.2] - 2025-10-06
--------------------

**Changed**

- Finalize version for 0.3.2 release (packaging metadata bump from 0.3.2.dev0).

[0.3.1] - 2025-10-05
--------------------

**Added**

- `amp_benchkit.cli` wrapper module and console script entry points: `amp-benchkit`, `amp-benchkit-gui`.
- `sweep` CLI subcommand that generates linear or log-spaced frequency lists, plus README usage examples.
- Bundled `results/sweep_scope.csv` dataset for quick automation demos.

**Changed**

- Recommended invocation now routes through the console scripts instead of `python unified_gui_layout.py`.
- Hardened FY generator sweep handling (CH2 handshake validation and frequency input checks) to avoid partial command sequences.

**Fixed**

- Docker image now copies the `patches/` directory reliably and installs PySide6 wheels by switching to a `python:3.11-slim` base.
- Corrected metric values in the bundled `results/sweep_scope.csv` sample data.

**Internal / Tooling**

- Added pre-commit configuration (ruff, black, mypy, large-file and virtualenv guards) and a CI workflow stub.
- Expanded project metadata (PyPI classifiers, SECURITY policy) and hardened U3 helpers for mypy/pytest coverage.

[0.3.0] - 2025-09-28
--------------------

**Added**

- New `amp_benchkit.automation` module exposing headless sweep helpers (`build_freq_list`, `sweep_scope_fixed`, `sweep_audio_kpis`).
- Unit tests for automation orchestration (freq list, sweep KPI path, THD/knees logic injection).
- Community documents: `CODE_OF_CONDUCT.md`, `CONTRIBUTING.md`.
- TestPyPI release candidate workflow (`.github/workflows/testpypi.yml`) for tags like `v0.3.0-rc1`.
- README badges (CI, License, Python versions, PyPI) and Development section (lint/format/type instructions).

**Changed**

- `unified_gui_layout.py` now delegates sweep/KPI methods to the automation module; original behavior preserved.
- Improved internal separation between GUI widgets and orchestration logic for easier scripting reuse.

**Fixed**

- Resolved ambiguous truthiness check on NumPy arrays when computing KPI metrics (explicit length check in automation module).

**Internal / Tooling**

- Expanded test count (now covers automation flows without hardware by dependency injection).
- Added release candidate publishing path distinct from stable PyPI tags.

[0.2.0] - 2025-09-28
--------------------

**Added**

- Completed extraction of all GUI tabs into `amp_benchkit.gui` (`generator`, `scope`, `daq`, `automation`, `diagnostics`).
- Added LabJack U3 helper parity functions (`u3_read_multi`, etc.) to `u3util` for modular tabs.
- Introduced lazy (in-function) Qt imports across tab builders for headless test resilience.

**Changed**

- Centralized `FY_PROTOCOLS` in `amp_benchkit.fy` and updated generator and automation tabs to reference it.
- Refactored `unified_gui_layout.py` to delegate all tab construction to builder functions.

**Removed**

- Deprecated DSP wrapper functions (`vrms`, `vpp`, `thd_fft`, `find_knees`) from `unified_gui_layout.py`; users should import from `amp_benchkit.dsp` directly.

**Fixed**

- Eliminated headless Qt import errors (`libEGL.so.1` issues) by moving PySide6 imports inside builder functions.

**Internal / Tooling**

- Updated tests to import DSP functions from `amp_benchkit.dsp` directly (no deprecation warnings remain).
- Roadmap docs (`DEV_GUI_MODULARIZATION.md`) updated to reflect completed modularization milestone.

[0.1.2] - 2025-09-??
--------------------

**Added**

- Initial extraction of generator, scope, and DAQ tabs; logging subsystem; config persistence; CI workflows; DSP module.

[0.1.1] - 2025-09-??
--------------------

**Added**

- Early modularization (deps, instruments) and test scaffolding.

[0.1.0] - 2025-09-??
--------------------

**Added**

- Initial monolithic `unified_gui_layout.py` with multi-tab GUI and instrumentation helpers.

---

Unreleased changes will accumulate here until the next tagged version.
