# Production launch smoke

- Timestamp UTC: 2026-06-04T14:08:53Z
- Artifact: build/release/production/gridOS-1.0.4-12-fe73021.dmg
- Artifact SHA-256: ca9ace5da768270d8fe81261c36b3e53239bcf6576e9727d9d728685d2c60640
- Source commit: fe73021
- Version: 1.0.4
- Build: 12
- Bundle ID: com.aaldere1.gridos
- Launch path: DMG mounted under /tmp/gridos-computer-1.0.4.2FCpAm
- Launch command: open -n "$APP"
- Process detector: ps -axo pid,ppid,comm,args | rg '[g]ridOS'
- Result: PASS

## DMG Container

```text
build/release/production/gridOS-1.0.4-12-fe73021.dmg: valid on disk
build/release/production/gridOS-1.0.4-12-fe73021.dmg: satisfies its Designated Requirement
build/release/production/gridOS-1.0.4-12-fe73021.dmg: accepted
source=Notarized Developer ID
stapler=PASS
```

## Gatekeeper

```text
/tmp/gridos-computer-1.0.4.2FCpAm/gridOS.app: accepted
source=Notarized Developer ID
origin=Developer ID Application: CineConcerts LLC (JFE428WL4Z)
```

## Strict Code Signature

```text
/tmp/gridos-computer-1.0.4.2FCpAm/gridOS.app: valid on disk
/tmp/gridos-computer-1.0.4.2FCpAm/gridOS.app: satisfies its Designated Requirement
```

## Process And Version Sample

```text
VERSION=1.0.4
BUILD=12
BUNDLE_ID=com.aaldere1.gridos
DMG_SHA256=ca9ace5da768270d8fe81261c36b3e53239bcf6576e9727d9d728685d2c60640
APP_BUNDLE_SHA256=800fa6a05b318c0319b8387fe0997f8b548f27c0f7bdac7422e849cef924be09
PID=35507
PS_SAMPLE=/private/tmp/gridos-computer-1.0.4.2FCpAm/gridOS.app/Contents/MacOS/gridOS
```

## DMG Installer Layout

Computer Use inspected the mounted DMG Finder window named `gridOS`.

- gridOS.app icon visible: PASS
- Applications shortcut visible: PASS
- Drag arrow/background visible: PASS
- Readable copy: PASS, "Drag gridOS into Applications"
- Footer: PASS, "signed and notarized"
- Applications link target: /Applications

## Visual Inspection

Computer Use targeted the mounted app path directly:
`/tmp/gridos-computer-1.0.4.2FCpAm/gridOS.app`.

- Visible app version: v1.0.4
- Terminal workspace inspection: PASS
- Pane toolbar visible: PASS
- Pane count visible: PASS, 4 panes restored
- Open Folder toolbar item visible: PASS
- AI Command Helper menu visible: PASS
- AI Command Helper menu opens: PASS
- Right-rail local signal visible: PASS
- Live system pulse/activity visible: PASS
- Pre-release/debug language visible in app UI: none observed
- Layout issues observed: none blocking
- Text clipping/bleed observed: none after 1.0.4 clipping fix

## Local Installed Copy Boundary

Computer Use initially attached to `/Applications/gridOS.app`, which this Mac
had installed from an earlier test. That installed copy reported:

```text
CFBundleShortVersionString=1.0.0
CFBundleVersion=8
```

The mounted 1.0.4 DMG app was running separately and reported:

```text
CFBundleShortVersionString=1.0.4
CFBundleVersion=12
```

This was not an artifact failure. The mounted 1.0.4 DMG app was inspected
separately and passed. After release publication, the stale NEXUS
`/Applications/gridOS.app` copy was replaced from the 1.0.4 DMG; Computer Use
then verified the installed Applications copy showed visible `v1.0.4`.

## Quit And Cleanup

- Quit/cleanup command: terminate test app processes and detach temporary DMG mount
- Quit status: PASS
- DMG detach status: PASS
- Temporary mount cleanup: PASS

## Notes

This smoke uses LaunchServices and Computer Use rather than directly executing
the app binary, so it matches the normal downloaded-DMG launch path more
closely. It does not capture shell history, terminal output, environment
variables, screenshots, API keys, private file contents, generated commands,
provider responses, or raw terminal transcripts.
