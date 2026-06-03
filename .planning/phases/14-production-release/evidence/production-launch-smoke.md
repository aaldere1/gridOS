# Production launch smoke

- Timestamp UTC: 2026-06-03T13:05:00Z
- Artifact: build/release/production/gridOS-1.0.0-8-b31bd2a.dmg
- Source commit: b31bd2a
- Version: 1.0.0
- Build: 8
- Bundle ID: com.aaldere1.gridos
- Launch path: DMG mounted at /tmp/gridos-version-smoke.Ek6wZh
- Launch command: open -n "$APP"
- Process detector: pgrep -x gridOS
- Result: PASS

## Gatekeeper

```text
/tmp/gridos-version-smoke.Ek6wZh/gridOS.app: accepted
source=Notarized Developer ID
```

## Strict Code Signature

```text
/tmp/gridos-version-smoke.Ek6wZh/gridOS.app: valid on disk
/tmp/gridos-version-smoke.Ek6wZh/gridOS.app: satisfies its Designated Requirement
```

## Process Sample

```text
VERSION=1.0.0
BUILD=8
BUNDLE_ID=com.aaldere1.gridos
PID=90661
CPU_PERCENT=0.0
RSS_KB=103360
PHYSICAL_FOOTPRINT=84.9M
PHYSICAL_FOOTPRINT_PEAK=106.5M
PS_SAMPLE=90661     1   0.0 103408   00:06 /private/tmp/gridos-version-smoke.Ek6wZh/gridOS.app/Contents/MacOS/gridOS
```

## Quit And Cleanup

- Quit command: osascript -e 'tell application id "com.aaldere1.gridos" to quit'
- Quit status: PASS
- DMG detach status: PASS
- Temporary mount cleanup: PASS

## Visual Version Inspection

- Screenshot capture: PASS
- Screenshot dimensions: 2144 x 1568
- Screenshot artifact: not committed; it includes local machine context.
- Visible app version: v1.0.0
- Main workspace inspection: PASS
- Pre-release/debug language visible in app UI: none observed
- Layout issues observed: none observed
- Text clipping observed: none observed

## Notes

This smoke uses LaunchServices rather than directly executing the app binary,
so it matches the normal downloaded-DMG launch path more closely. It does not
capture shell history, terminal output, environment variables, screenshots, API
keys, or private file paths beyond the temporary artifact mount.
