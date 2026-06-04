# gridOS 1.0.4 to 1.0.5 local update proof

Timestamp: 2026-06-04T16:03:45Z

Status: PASS

## Scope

This proof validates local direct-download replacement mechanics without relying
on a clean Mac. It proves the final DMG can replace the prior direct-download
app bundle and preserve signing/Gatekeeper validity after replacement. It does
not prove first-run quarantine behavior on a fresh user account or a clean Mac.

## Artifacts

| Artifact | Version | Build | SHA-256 |
| --- | --- | --- | --- |
| `build/release/production/gridOS-1.0.4-12-fe73021.dmg` | 1.0.4 | 12 | `ca9ace5da768270d8fe81261c36b3e53239bcf6576e9727d9d728685d2c60640` |
| `build/release/production/gridOS-1.0.5-13-379289a.dmg` | 1.0.5 | 13 | `b3f94f03ca5db2f1c3fa9fb1df0fa0cdcacd6998927a878fc6b312768e0c5a05` |

## Procedure

1. Created a temporary install root under `/tmp`.
2. Mounted the 1.0.4 DMG read-only with `hdiutil`.
3. Copied `gridOS.app` from the mounted 1.0.4 DMG into the temporary install root.
4. Verified the installed copy reported version `1.0.4`, build `12`.
5. Ran strict `codesign --verify` against the temporary 1.0.4 app copy.
6. Detached the 1.0.4 DMG.
7. Mounted the 1.0.5 DMG read-only with `hdiutil`.
8. Replaced the temporary installed app with `gridOS.app` from the mounted 1.0.5 DMG.
9. Verified the replaced copy reported version `1.0.5`, build `13`.
10. Ran strict `codesign --verify` against the temporary 1.0.5 app copy.
11. Ran `spctl -a -vv -t exec` against the temporary 1.0.5 app copy.

## Results

| Check | Result |
| --- | --- |
| 1.0.4 DMG mounted read-only | PASS |
| 1.0.4 app copied into temporary install root | PASS |
| Installed app reported version `1.0.4` build `12` | PASS |
| 1.0.4 strict codesign verification | PASS |
| 1.0.5 DMG mounted read-only | PASS |
| Existing temporary install replaced by 1.0.5 app | PASS |
| Replaced app reported version `1.0.5` build `13` | PASS |
| 1.0.5 strict codesign verification | PASS |
| 1.0.5 Gatekeeper execution assessment | PASS |

Gatekeeper result:

```text
/tmp/.../gridOS.app: accepted
source=Notarized Developer ID
```

The replaced 1.0.5 app bundle tree hash was:

```text
05cc09d1b6fcd010bef4505b63eea99ba0e4185b364eecfb95191fae331acbf7
```

## Boundary

This pass proves version-to-version replacement with the current signed and
notarized DMG. Clean-Mac Finder install/update proof remains the external UAT
step for quarantine behavior, user account state, and first-launch Gatekeeper
UX.
