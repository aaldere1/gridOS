# Phase 5 Aesthetic Mode Evidence

This directory contains local screenshot evidence for the Phase 5 visual-mode checkpoint.

All screenshot files are app-window isolated. The helper activates gridOS, sets the main window to the deterministic `160,120,1440,900` point rectangle, resolves the gridOS CoreGraphics window ID, and captures that window with non-interactive `screencapture -x -l`. The evidence is not full-desktop capture and excludes unrelated desktop, browser, chat, and foreground app content.

## Mode Comparison Set

All screenshots in this set must use the exact shared install seed `phase5-evidence-shared-seed` so mode differences are not confounded by per-install seed changes.

| Raw mode | Display name | File |
| --- | --- | --- |
| `tron` | Tron | `tron.png` |
| `severance` | Severance | `severance.png` |
| `appleNative` | Apple-native | `apple-native.png` |

## Install Variation Set

All screenshots in this set use raw mode `tron` with three different install seeds. Variation should be subtle and visible without harming terminal or metrics readability.

| Raw mode | Seed label | File |
| --- | --- | --- |
| `tron` | `phase5-tron-install-a` | `tron-install-a.png` |
| `tron` | `phase5-tron-install-b` | `tron-install-b.png` |
| `tron` | `phase5-tron-install-c` | `tron-install-c.png` |

## Preference Keys and Shortcut

- Visual mode preference key: `appearance.visualMode`
- Install seed preference key: `appearance.installSeed`
- Mode switch shortcut: `.keyboardShortcut("m", modifiers: [.command, .shift])`

## Capture Status

Automated app-window-isolated capture completed on 2026-05-20. `sips -g pixelWidth -g pixelHeight .planning/phases/05-aesthetic-modes/evidence/*.png` reported all six mode/variation screenshots at `3104x2024`; after the terminal-focus smoke, the dedicated proof screenshot also reports `3104x2024`.

Files produced:

- `tron.png`
- `severance.png`
- `apple-native.png`
- `tron-install-a.png`
- `tron-install-b.png`
- `tron-install-c.png`
- `focus-smoke-command-shift-m.png`

## Command-Shift-M terminal-focus smoke

Before Phase 5 is approved, launch the app, focus the terminal, type a harmless marker, press `Command-Shift-M` repeatedly, verify the mode indicator changes, verify shell input remains accepted after each switch, and record the pass/fail result in `05-04-SUMMARY.md` or this README.

Smoke result: passed on 2026-05-20. Starting from `appearance.visualMode=tron` and install seed `phase5-focus-smoke`, the terminal accepted input before switching. `Command-Shift-M` then cycled `severance -> appleNative -> tron`, and the embedded terminal accepted shell input after each mode switch. Marker files created during the smoke were `/tmp/gridos_phase5_focus_before`, `/tmp/gridos_phase5_focus_after_1`, `/tmp/gridos_phase5_focus_after_2`, and `/tmp/gridos_phase5_focus_after_3`.

Proof screenshot: `focus-smoke-command-shift-m.png` shows the terminal markers after all three cycles and the final Tron mode indicator.

## Deferred Ideas

Cyberpunk, Matrix, sound themes, plugin/user themes, full light mode, GPU terminal text rendering, marketplace/import themes, and eDEX theme compatibility are explicitly deferred and out of scope for this Phase 5 evidence checkpoint.
