# Production launch smoke

- Timestamp UTC: 2026-06-03T12:06:50Z
- Artifact: build/release/production/gridOS-0.1.0-7-ebbfd6f.dmg
- Source commit: ebbfd6f
- Version: 0.1.0
- Build: 7
- Bundle ID: com.aaldere1.gridos
- Launch path: DMG mounted at /tmp/gridos-production-smoke.D0hk4x
- Launch command: open -n "$APP"
- Process detector: pgrep -x gridOS
- Result: PASS

## Gatekeeper

```text
/tmp/gridos-production-smoke.D0hk4x/gridOS.app: accepted
source=Notarized Developer ID
```

## Strict Code Signature

```text
/tmp/gridos-production-smoke.D0hk4x/gridOS.app: valid on disk
/tmp/gridos-production-smoke.D0hk4x/gridOS.app: satisfies its Designated Requirement
```

## Process Sample

```text
PID=4328
CPU_PERCENT=0.0
RSS_KB=113936
PHYSICAL_FOOTPRINT=81.9M
PHYSICAL_FOOTPRINT_PEAK=102.4M
PS_SAMPLE= 4328     1   0.0 114000   00:07 /private/tmp/gridos-production-smoke.D0hk4x/gridOS.app/Contents/MacOS/gridOS
LSOF_SAMPLE=gridOS  4328 aaldere1  txt    REG              1,208   1435216                  21 /private/tmp/gridos-production-smoke.D0hk4x/gridOS.app/Contents/MacOS/gridOS
```

## Quit And Cleanup

- Quit command: osascript -e 'tell application id "com.aaldere1.gridos" to quit'
- Quit status: PASS
- DMG detach status: PASS
- Temporary mount cleanup: PASS

## Visual First-Launch Inspection

- Screenshot capture: PASS
- Screenshot dimensions: 2144 x 1568
- Screenshot artifact: not committed; it includes local machine context.
- First-launch briefing: PASS
- Beta/debug language visible in app UI: none observed
- Layout issues observed: none observed
- Text clipping observed: none observed

## Notes

This smoke uses LaunchServices rather than directly executing the app binary,
so it matches the normal downloaded-DMG launch path more closely. It does not
capture shell history, terminal output, environment variables, screenshots, API
keys, or private file paths beyond the temporary artifact mount.
