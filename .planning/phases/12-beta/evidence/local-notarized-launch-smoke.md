# Local notarized launch smoke

- Timestamp UTC: 2026-05-21T21:58:22Z
- Artifact basename: `gridOS-0.1.0-1-20b35f0.dmg`
- Source commit: `20b35f0`
- Marker command: `--cmd` with deterministic `/tmp` marker
- Privacy disclosure handling: local preference was temporarily set to reviewed, then restored
- Session handling: saved local session files were temporarily moved aside, then restored
- Marker result: PASS
- Process launch: PASS
- CPU sample while launched: 6.8%
- Quit cleanup: PASS
- DMG detach cleanup: PASS
- Result: PASS

This is a local smoke against the notarized DMG. It does not replace clean-Mac
Gatekeeper UAT, but it verifies the notarized app launches, accepts a startup
terminal command, and can quit without leaving the app process or mounted DMG
behind. Evidence is sanitized and records no terminal transcript, shell history,
environment dump, screenshot, private path, account value, or build artifact.
