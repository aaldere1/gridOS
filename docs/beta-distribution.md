# Beta distribution

## Scope

Phase 12 uses a manual Beta update flow backed by
`.planning/phases/12-beta/beta-release-manifest.json`. Future Sparkle/appcast
work remains compatible with this manifest, but automatic in-app updates are not
required for this manual Beta lane.

The default external artifact is the notarized DMG produced by
`scripts/build-beta.sh`, submitted by `scripts/notarize-beta-artifact.sh`, and
verified by `scripts/verify-beta-artifact.sh`.

## Download

Use the current Beta artifact basename from
`.planning/phases/12-beta/beta-release-manifest.json`.

Do not distribute artifacts from `.planning`. Beta artifacts should come from an
ignored local output directory such as `build/beta` or from the eventual hosted
download location.

## Verify checksum

Compare the downloaded artifact SHA-256 to the manifest:

```sh
shasum -a 256 path/to/gridOS-beta.dmg
```

The checksum must match `.planning/phases/12-beta/beta-release-manifest.json`
before installation.

## Install

1. Open the DMG.
2. Copy `gridOS.app` to `/Applications` or the tester's chosen Applications folder.
3. Eject the DMG.
4. Launch `gridOS.app` from Finder.

If Gatekeeper blocks launch, record the blocker in
`.planning/phases/12-beta/BETA-UAT.md` and do not tell testers to bypass
Gatekeeper.

## First launch

The first launch should show the Privacy & Safety disclosure before normal use.
The disclosure must explain that terminal sessions stay local, Command
Intelligence is opt-in, API keys are stored in Keychain, risky commands are
inserted for review, notifications and workspace indexing are opt-in, and
diagnostics are local, sanitized, and user-reviewed.

## Update from Beta N to Beta N+1

The manual Beta update flow is:

1. Quit the currently installed Beta.
2. Download the Beta N+1 artifact.
3. Verify the Beta N+1 SHA-256 against the manifest.
4. Open the DMG and replace the installed `gridOS.app`.
5. Launch from Finder.
6. Confirm the version/build in the manifest matches the app bundle metadata.
7. Record the update result in `.planning/phases/12-beta/BETA-UAT.md`.

This flow is the Phase 12 equivalent update mechanism until a hosted Sparkle or
appcast lane is deliberately added and verified.

## Rollback

Keep the previous Beta artifact available until Beta N+1 is verified. To roll
back:

1. Quit gridOS.
2. Replace the installed app with the previous verified artifact.
3. Launch from Finder.
4. Record the rollback result and reason in `.planning/phases/12-beta/BETA-UAT.md`.

## Feedback

Use `.planning/phases/12-beta/BETA-FEEDBACK.md` for tester reports. Reports
should include app version/build, artifact basename, macOS version, hardware
class, install path category, sanitized steps, expected result, actual result,
and blocker category.

## Privacy boundaries

Testers must not send shell history, terminal transcripts, environment
variables, API keys, prompts, generated commands, provider responses,
screenshots with secrets, or private file paths.

No telemetry, crash upload, or automatic diagnostics upload is added in Phase 12.
