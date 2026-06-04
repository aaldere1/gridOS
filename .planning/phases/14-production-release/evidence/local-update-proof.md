# gridOS 1.0.2 to 1.0.4 local update proof

Timestamp: 2026-06-04T14:08:53Z

Status: PASS

## Scope

This proof validates local direct-download replacement mechanics without relying
on a clean Mac. It proves the final DMG can replace the prior direct-download
app bundle and preserve signing/Gatekeeper validity after replacement. It does
not prove first-run quarantine behavior on a fresh user account or a clean Mac.

## Artifacts

| Artifact | Version | Build | SHA-256 |
| --- | --- | --- | --- |
| `build/release/production/gridOS-1.0.2-10-8f2865b.dmg` | 1.0.2 | 10 | `52db1e21ee81df5b5f6e1bda5aec05888baf64277bbe13fe8d5703ad402f867c` |
| `build/release/production/gridOS-1.0.4-12-fe73021.dmg` | 1.0.4 | 12 | `ca9ace5da768270d8fe81261c36b3e53239bcf6576e9727d9d728685d2c60640` |

## Procedure

1. Created a temporary install root under `/tmp`.
2. Mounted the 1.0.2 DMG read-only with `hdiutil`.
3. Copied `gridOS.app` from the mounted 1.0.2 DMG into the temporary install root.
4. Verified the installed copy reported version `1.0.2`, build `10`.
5. Ran strict `codesign --verify` against the temporary 1.0.2 app copy.
6. Detached the 1.0.2 DMG.
7. Mounted the 1.0.4 DMG read-only with `hdiutil`.
8. Replaced the temporary installed app with `gridOS.app` from the mounted 1.0.4 DMG.
9. Verified the replaced copy reported version `1.0.4`, build `12`.
10. Ran strict `codesign --verify` against the temporary 1.0.4 app copy.
11. Ran `spctl -a -vv -t exec` against the temporary 1.0.4 app copy.

## Results

| Check | Result |
| --- | --- |
| 1.0.2 DMG mounted read-only | PASS |
| 1.0.2 app copied into temporary install root | PASS |
| Installed app reported version `1.0.2` build `10` | PASS |
| 1.0.2 strict codesign verification | PASS |
| 1.0.4 DMG mounted read-only | PASS |
| Existing temporary install replaced by 1.0.4 app | PASS |
| Replaced app reported version `1.0.4` build `12` | PASS |
| 1.0.4 strict codesign verification | PASS |
| 1.0.4 Gatekeeper execution assessment | PASS |

Gatekeeper result:

```text
/tmp/.../Applications/gridOS.app: accepted
source=Notarized Developer ID
origin=Developer ID Application: CineConcerts LLC (JFE428WL4Z)
```

The replaced 1.0.4 app bundle tree hash was:

```text
800fa6a05b318c0319b8387fe0997f8b548f27c0f7bdac7422e849cef924be09
```

## Boundary

This pass proves version-to-version replacement with the current signed and
notarized DMG. Clean-Mac Finder install/update proof remains the external UAT
step for quarantine behavior, user account state, and first-launch Gatekeeper
UX.
