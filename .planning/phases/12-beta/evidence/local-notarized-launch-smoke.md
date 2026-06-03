# Local notarized launch smoke

- Timestamp UTC: 2026-06-03T11:27:03Z
- Artifact basename: `gridOS-0.1.0-6-e1c7005.dmg`
- Final DMG SHA-256: `fc4e353604f7b5195678fc86320633a4918955146db7429146133f8be495879d`
- Source commit: `e1c7005`
- Marker command: `--cmd` with deterministic `/tmp` marker
- Marker value: `GRIDOS_PHASE12_BUILD6_SMOKE`
- Privacy disclosure handling: local preference was temporarily set to reviewed, then restored
- Session handling: saved local session files were temporarily moved aside, then restored
- Marker result: PASS
- Process launch: PASS
- CPU sample while launched: 4.4%
- Quit cleanup: PASS
- DMG detach cleanup: PASS
- Cleanup follow-up: PASS; no `gridOS` process, DMG mount, or smoke temp directories remained
- Result: PASS

This is a local smoke against the notarized DMG. It does not replace clean-Mac
Gatekeeper UAT, but it verifies the notarized app launches, accepts a startup
terminal command, and can quit without leaving the app process or mounted DMG
behind. Evidence is sanitized and records no terminal transcript, shell history,
environment dump, screenshot, private path, account value, or build artifact.
