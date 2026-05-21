# Notarization setup

This document is the Phase 12 unblock path for `BETA_NOTARIZATION_BLOCKED`.

gridOS uses direct Developer ID distribution. Apple notarization should be done
with `notarytool` and a Keychain profile created outside the repo. Do not commit
Apple IDs, app-specific passwords, API keys, private key files, Keychain
contents, notary logs with private paths, or raw command output.

## Create a Keychain profile

Preferred profile name:

```sh
export GRIDOS_NOTARY_PROFILE=gridOS-beta
```

Apple ID/app-specific password mode:

```sh
export GRIDOS_NOTARY_APPLE_ID='apple-id@example.com'
export GRIDOS_NOTARY_TEAM_ID='JFE428WL4Z'
scripts/setup-beta-notary-profile.sh "$GRIDOS_NOTARY_PROFILE"
```

`notarytool` prompts for the app-specific password. Do not put the password in
shell history or committed files.

App Store Connect API key mode:

```sh
export GRIDOS_NOTARY_KEY_PATH='/private/path/AuthKey_ABC123DEFG.p8'
export GRIDOS_NOTARY_KEY_ID='ABC123DEFG'
export GRIDOS_NOTARY_ISSUER_ID='00000000-0000-0000-0000-000000000000'
scripts/setup-beta-notary-profile.sh "$GRIDOS_NOTARY_PROFILE"
```

## Check the profile

```sh
GRIDOS_NOTARY_PROFILE=gridOS-beta scripts/check-beta-notary-profile.sh
```

The check writes presence-only evidence to
`.planning/phases/12-beta/evidence/beta-notary-profile-check.txt`.

## Rerun the Beta lane

```sh
export GRIDOS_DEVELOPMENT_TEAM=JFE428WL4Z
export GRIDOS_SIGNING_IDENTITY='Developer ID Application: CineConcerts LLC (JFE428WL4Z)'
export GRIDOS_NOTARY_PROFILE=gridOS-beta

scripts/beta-notarization-preflight.sh
scripts/build-beta.sh
scripts/notarize-beta-artifact.sh build/beta/gridOS-version-build-commit.dmg
scripts/verify-beta-artifact.sh build/beta/gridOS-version-build-commit.dmg
scripts/write-beta-release-manifest.sh build/beta/gridOS-version-build-commit.dmg
```

After those pass, run the clean-Mac Gatekeeper UAT in
`.planning/phases/12-beta/BETA-UAT.md` and update
`.planning/phases/12-beta/12-VERIFICATION.md` from `BLOCKED` to `PASS`.

## References

- Apple notarization overview: `https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution`
- Apple custom notarization workflow: `https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution/customizing_the_notarization_workflow`
- Apple notarytool migration note: `https://developer.apple.com/documentation/technotes/tn3147-migrating-to-the-latest-notarization-tool`
