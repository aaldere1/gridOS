# Production launch smoke

- Timestamp UTC: 2026-06-03T13:39:04Z
- Artifact: build/release/production/gridOS-1.0.1-9-3f74ed7.dmg
- Source commit: 3f74ed7
- Version: 1.0.1
- Build: 9
- Bundle ID: com.aaldere1.gridos
- Launch path: DMG mounted at /tmp/gridos-101-smoke.o8MFmN
- Launch command: open -n "$APP"
- Process detector: pgrep -x gridOS
- Result: PASS

## Gatekeeper

```text
/tmp/gridos-101-smoke.o8MFmN/gridOS.app: accepted
source=Notarized Developer ID
```

## Strict Code Signature

```text
/tmp/gridos-101-smoke.o8MFmN/gridOS.app: valid on disk
/tmp/gridos-101-smoke.o8MFmN/gridOS.app: satisfies its Designated Requirement
```

## Process Sample

```text
VERSION=1.0.1
BUILD=9
BUNDLE_ID=com.aaldere1.gridos
PID=99677
CPU_PERCENT=2.3
RSS_KB=106448
PS_SAMPLE=99677     1   2.3 106448   00:03 /private/tmp/gridos-101-smoke.o8MFmN/gridOS.app/Contents/MacOS/gridOS
```

## Visual Inspection

- Computer Use app path: /tmp/gridos-101-smoke.o8MFmN/gridOS.app
- Visible app version: v1.0.1
- Terminal workspace inspection: PASS
- Pane toolbar visible: PASS
- Pane count visible: PASS, 4 panes restored
- Command Intelligence settings menu path: PASS
- Settings section focus: PASS
- Provider picker exposes Anthropic and OpenAI: PASS
- Default provider restored/left as Anthropic: PASS
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
