# Production launch smoke

- Timestamp UTC: 2026-06-04T16:03:45Z
- Artifact: build/release/production/gridOS-1.0.5-13-379289a.dmg
- Artifact SHA-256: b3f94f03ca5db2f1c3fa9fb1df0fa0cdcacd6998927a878fc6b312768e0c5a05
- Source commit: 379289a
- Version: 1.0.5
- Build: 13
- Bundle ID: com.aaldere1.gridos
- Mounted launch path: /tmp/gridos-1.0.5-ui.Yec5uq/gridOS.app
- Installed launch path: /Applications/gridOS.app
- Result: PASS

## DMG Container

```text
build/release/production/gridOS-1.0.5-13-379289a.dmg: valid on disk
build/release/production/gridOS-1.0.5-13-379289a.dmg: satisfies its Designated Requirement
build/release/production/gridOS-1.0.5-13-379289a.dmg: accepted
source=Notarized Developer ID
stapler=PASS
```

## Gatekeeper

```text
/tmp/gridos-1.0.5-ui.Yec5uq/gridOS.app: accepted
source=Notarized Developer ID
origin=Developer ID Application: CineConcerts LLC (JFE428WL4Z)
```

## Strict Code Signature

```text
/tmp/gridos-1.0.5-ui.Yec5uq/gridOS.app: valid on disk
/tmp/gridos-1.0.5-ui.Yec5uq/gridOS.app: satisfies its Designated Requirement
```

## Process And Version Sample

```text
VERSION=1.0.5
BUILD=13
BUNDLE_ID=com.aaldere1.gridos
DMG_SHA256=b3f94f03ca5db2f1c3fa9fb1df0fa0cdcacd6998927a878fc6b312768e0c5a05
APP_BUNDLE_SHA256=05cc09d1b6fcd010bef4505b63eea99ba0e4185b364eecfb95191fae331acbf7
VISIBLE_VERSION=v1.0.5
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
`/tmp/gridos-1.0.5-ui.Yec5uq/gridOS.app`.

- Visible app version: v1.0.5
- Terminal workspace inspection: PASS
- Pane toolbar visible: PASS
- Pane count visible: PASS, restored panes visible
- AI Command Helper menu visible: PASS
- AI Command Helper opens with Command-K: PASS
- AI Command Helper mode guidance visible: PASS
  - Suggest Command: PASS, use/provide/get copy visible
  - Explain Output: PASS, read-only diagnosis copy visible
  - Fix Failed Command: PASS, failed command/output guidance visible
- AI Command Helper provider setup state: PASS, missing key is explicit and no
  request leaves the app until configured.
- Preview-first copy visible: PASS
- Pre-release/debug language visible in app UI: none observed
- Layout issues observed: none blocking
- Text clipping/bleed observed: none blocking

## Settings Inspection

Computer Use clicked `Add Provider Key` from Command-K and verified Settings
opened directly to the AI Command Helper section.

- AI Command Helper heading and info bubble visible: PASS
- "How it works" card visible: PASS
- Provider/model/key setup visible: PASS
- Provider not configured copy visible: PASS
- Model ID custom field visible: PASS
- Settings full screen/zoom control exposes zoom action: PASS
- Settings resize proof: PASS

Resize proof through System Events:

```text
before=700, 640
after=980, 780
```

## Installed Applications Copy

The signed/notarized 1.0.5 app was copied from the mounted DMG into
`/Applications/gridOS.app` after preserving the previous local app bundle under
`/tmp/gridos-install-backup.c9HYIX`.

```text
CFBundleShortVersionString=1.0.5
CFBundleVersion=13
/Applications/gridOS.app: valid on disk
/Applications/gridOS.app: satisfies its Designated Requirement
/Applications/gridOS.app: accepted
source=Notarized Developer ID
```

Computer Use then targeted `/Applications/gridOS.app` and verified:

- Visible app version: v1.0.5
- Command-K opens AI Command Helper: PASS
- Mode guidance and missing-key setup copy visible: PASS

## Quit And Cleanup

- Quit/cleanup command: terminate test app processes and detach temporary DMG mounts
- Quit status: PASS
- DMG detach status: PASS
- Temporary mount cleanup: PASS

## Notes

This smoke uses LaunchServices and Computer Use rather than directly executing
the app binary, so it matches the normal downloaded-DMG launch path more
closely. It does not capture shell history, terminal output, environment
variables, screenshots, API keys, private file contents, generated commands,
provider responses, or raw terminal transcripts.
