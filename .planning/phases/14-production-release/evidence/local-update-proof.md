# gridOS 1.0.1 to 1.0.2 local update proof

Timestamp: 2026-06-03T16:52:54Z

Status: PASS

## Scope

This proof validates local direct-download replacement mechanics without
touching the user's `/Applications` folder. It is not clean-Mac evidence. A
separate clean Mac should still verify Finder drag-install, Gatekeeper first
launch, and user-environment replacement.

## Artifacts

| Artifact | Version | Build | SHA-256 |
| --- | --- | --- | --- |
| `build/release/production/gridOS-1.0.1-9-3f74ed7.dmg` | 1.0.1 | 9 | `39a64bb9a8d605bcac8089f3a410e67f44a4d87042949880c79ab7c34205824a` |
| `build/release/production/gridOS-1.0.2-10-8f2865b.dmg` | 1.0.2 | 10 | `52db1e21ee81df5b5f6e1bda5aec05888baf64277bbe13fe8d5703ad402f867c` |

## Procedure

1. Created a temporary install root at `/tmp/gridos-update-proof.3Suvcr/Applications`.
2. Mounted the 1.0.1 DMG read-only with `hdiutil`.
3. Copied `gridOS.app` from the mounted 1.0.1 DMG into the temporary install root.
4. Verified the installed copy reported version `1.0.1`, build `9`.
5. Ran strict `codesign --verify` against the temporary 1.0.1 app copy.
6. Detached the 1.0.1 DMG.
7. Mounted the 1.0.2 DMG read-only with `hdiutil`.
8. Replaced the temporary installed app with `gridOS.app` from the mounted 1.0.2 DMG.
9. Verified the replaced copy reported version `1.0.2`, build `10`.
10. Ran strict `codesign --verify` against the temporary 1.0.2 app copy.
11. Ran `spctl -a -vv -t exec` against the temporary 1.0.2 app copy.

## Results

| Check | Result |
| --- | --- |
| 1.0.1 DMG mounted read-only | PASS |
| 1.0.1 app copied into temporary install root | PASS |
| Installed app reported version `1.0.1` build `9` | PASS |
| 1.0.1 strict codesign verification | PASS |
| 1.0.2 DMG mounted read-only | PASS |
| Existing temporary install replaced by 1.0.2 app | PASS |
| Replaced app reported version `1.0.2` build `10` | PASS |
| 1.0.2 strict codesign verification | PASS |
| 1.0.2 Gatekeeper execution assessment | PASS |

Gatekeeper result:

```text
/tmp/gridos-update-proof.3Suvcr/Applications/gridOS.app: accepted
source=Notarized Developer ID
origin=Developer ID Application: CineConcerts LLC (JFE428WL4Z)
```

The replaced 1.0.2 app bundle tree hash was:

```text
60cf2671925cf50ff6bf20c3c9928c72de6e1bb2be9c69e4b6b5b67253bbcbfa
```

## Boundary

This pass proves that the final DMG can replace the prior direct-download app
bundle and preserve signing/Gatekeeper validity after replacement. It does not
prove first-run quarantine behavior on a fresh user account or a clean Mac.
