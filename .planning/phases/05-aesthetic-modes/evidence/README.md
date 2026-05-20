# Phase 5 Aesthetic Mode Evidence

This directory contains local screenshot evidence for the Phase 5 visual-mode checkpoint.

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

## Command-Shift-M terminal-focus smoke

Before Phase 5 is approved, launch the app, focus the terminal, type a harmless marker, press `Command-Shift-M` repeatedly, verify the mode indicator changes, verify shell input remains accepted after each switch, and record the pass/fail result in `05-04-SUMMARY.md` or this README.

## Deferred Ideas

Cyberpunk, Matrix, sound themes, plugin/user themes, full light mode, GPU terminal text rendering, marketplace/import themes, and eDEX theme compatibility are explicitly deferred and out of scope for this Phase 5 evidence checkpoint.
