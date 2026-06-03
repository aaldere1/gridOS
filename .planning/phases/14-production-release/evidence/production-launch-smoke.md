# Production launch smoke

- Timestamp UTC: 2026-06-03T14:21:23Z
- Artifact: build/release/production/gridOS-1.0.2-10-8f2865b.dmg
- Artifact SHA-256: 52db1e21ee81df5b5f6e1bda5aec05888baf64277bbe13fe8d5703ad402f867c
- Source commit: 8f2865b
- Version: 1.0.2
- Build: 10
- Bundle ID: com.aaldere1.gridos
- Launch path: DMG mounted under /tmp/gridos-final-dmg.ZMK39u
- Launch command: open -n "$APP"
- Process detector: pgrep -x gridOS
- Result: PASS

## DMG Container

```text
build/release/production/gridOS-1.0.2-10-8f2865b.dmg: valid on disk
build/release/production/gridOS-1.0.2-10-8f2865b.dmg: satisfies its Designated Requirement
build/release/production/gridOS-1.0.2-10-8f2865b.dmg: accepted
source=Notarized Developer ID
stapler=PASS
```

## Gatekeeper

```text
/tmp/gridos-final-dmg.ZMK39u/gridOS.app: accepted
source=Notarized Developer ID
```

## Strict Code Signature

```text
/tmp/gridos-final-dmg.ZMK39u/gridOS.app: valid on disk
/tmp/gridos-final-dmg.ZMK39u/gridOS.app: satisfies its Designated Requirement
```

## Process Sample

```text
VERSION=1.0.2
BUILD=10
BUNDLE_ID=com.aaldere1.gridos
PID=90961
CPU_PERCENT=8.0
RSS_KB=14112
PS_SAMPLE=90961     1   8.0  14112 00:00 /tmp/gridos-final-dmg.ZMK39u/gridOS.app/Contents/MacOS/gridOS
```

## DMG Installer Layout

- Finder window bounds: {120, 120, 780, 540}
- gridOS.app icon position: {180, 220}
- Applications alias position: {500, 220}
- Hidden background asset position: {1000, 1000}
- Applications link target: /Applications
- Visible layout: PASS, custom drag-to-Applications background with arrow and readable drop targets
- Hidden-file stress check: PASS, .background remains hidden/off-canvas even with Finder hidden files enabled on this Mac

## Visual Inspection

- Computer Use app path: /tmp/gridos-final-dmg.ZMK39u/gridOS.app
- Visible app version: v1.0.2
- Terminal workspace inspection: PASS
- Pane toolbar visible: PASS
- Pane count visible: PASS, 4 panes restored
- AI Command Helper menu visible: PASS
- Settings section focus: PASS
- AI Command Helper info button present: PASS
- Provider setup copy visible: PASS
- Anthropic provider/model visible: PASS
- No-key copy: PASS, "Add an Anthropic key to use this provider. The terminal still works normally."
- Pre-release/debug language visible in app UI: none observed
- Layout issues observed: none blocking; four panes are usable but tight at the default window width
- Text clipping observed: none blocking

## Quit And Cleanup

- Quit command: osascript -e 'tell application id "com.aaldere1.gridos" to quit'
- Quit status: PASS
- DMG detach status: PASS
- Temporary mount cleanup: PASS

## Notes

This smoke uses LaunchServices rather than directly executing the app binary,
so it matches the normal downloaded-DMG launch path more closely. It does not
capture shell history, terminal output, environment variables, screenshots, API
keys, private file contents, generated commands, provider responses, or raw
terminal transcripts.
