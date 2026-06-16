# Production launch smoke

- Timestamp UTC: 2026-06-15T21:03:45Z
- Artifact: build/release/production/gridOS-1.0.6-14-edda1ee.dmg
- Artifact SHA-256: cf6e01770e43b94783fefa25493da01f2471b961280334f63fe804568a1fe9c1
- Source commit: edda1ee
- Version: 1.0.6
- Build: 14
- Bundle ID: com.aaldere1.gridos
- Mounted launch path: /tmp/gridos-1.0.6-ui.XY0nxW/gridOS.app
- Result: PASS

## DMG Container

```text
build/release/production/gridOS-1.0.6-14-edda1ee.dmg: accepted
source=Notarized Developer ID
stapler=PASS
```

## Gatekeeper

```text
/tmp/gridos-1.0.6-proof.gzx7wW/gridOS.app: accepted
source=Notarized Developer ID
origin=Developer ID Application: CineConcerts LLC (JFE428WL4Z)
```

## Strict Code Signature

```text
/tmp/gridos-1.0.6-proof.gzx7wW/gridOS.app: valid on disk
/tmp/gridos-1.0.6-proof.gzx7wW/gridOS.app: satisfies its Designated Requirement
```

## Process And Version Sample

```text
VERSION=1.0.6
BUILD=14
BUNDLE_ID=com.aaldere1.gridos
DMG_SHA256=cf6e01770e43b94783fefa25493da01f2471b961280334f63fe804568a1fe9c1
APP_BUNDLE_SHA256=7e2c55c1c2a0e5f76ccf8a1b16a2795f729270c04eaa13547ac9b284a70c25c2
VISIBLE_VERSION=v1.0.6
```

## Sparkle Settings

The mounted app Info.plist contains:

```text
SUFeedURL=https://raw.githubusercontent.com/aaldere1/gridOS/main/appcast.xml
SUPublicEDKey=nnzeMZKjZFLXB/2A8xiz01Nb+dOrs/5xpO1ig+v6+0A=
SUEnableAutomaticChecks=true
SUAutomaticallyUpdate=true
SUEnableSystemProfiling=false
```

The committed public Settings screenshot
`docs/assets/readme/screenshots/gridos-settings-updates.png` was inspected and
shows:

- Software Updates section: PASS
- Automatically check for updates toggle on: PASS
- Automatically download and install updates toggle on: PASS
- Check for Updates button: PASS
- Signed GitHub release assets copy: PASS
- System profiling off copy: PASS
- Username, terminal prompt, local path, and private file content: none visible

## Visual Inspection

Computer Use targeted the mounted app path directly:
`/tmp/gridos-1.0.6-ui.XY0nxW/gridOS.app`.

- Visible app version: v1.0.6
- Terminal workspace inspection: PASS
- Pane toolbar visible: PASS
- Pane count visible: PASS
- Right-rail signal visible: PASS
- System metrics visible: PASS
- Pre-release/debug language visible in app UI: none observed
- Layout issues observed: none blocking
- Text clipping/bleed observed: none blocking

The terminal surface correctly shows a live local shell prompt, including the
machine/user prompt. Because of that, terminal screenshots are intentionally not
used in public README imagery. Public imagery uses the generated hero and
settings/update screenshots instead.

## Embedded Sparkle Helpers

Strict code signature verification traversed the embedded Sparkle helpers:

```text
Sparkle.framework/Versions/B/Autoupdate: validated
Sparkle.framework/Versions/B/Updater.app: validated
Sparkle.framework/Versions/B/XPCServices/Downloader.xpc: validated
Sparkle.framework/Versions/B/XPCServices/Installer.xpc: validated
```

## Quit And Cleanup

- Quit/cleanup command: terminate mounted test app process and detach temporary DMG mount
- Quit status: PASS
- DMG detach status: PASS

## Notes

This smoke uses LaunchServices and Computer Use against the mounted DMG app path
so it matches the normal downloaded-DMG launch path. It does not commit shell
history, terminal output, environment variables, screenshots with user prompts,
API keys, private file contents, generated commands, provider responses, or raw
terminal transcripts.
