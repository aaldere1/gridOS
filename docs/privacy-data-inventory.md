# gridOS Privacy Data Inventory

## Data Inventory

| Data class | Sensitivity | Stored where | Leaves device? | Default behavior | User control |
| --- | --- | --- | --- | --- | --- |
| Provider API key | Secret | Keychain generic-password item through `GridOSKit.KeychainCredentialStore` | No, except as provider auth header during explicit request | Not configured by default | Save/delete in Command Intelligence settings |
| Provider/model preference | Low | `@AppStorage` keys in `GridOSAppPreferences` | No | Anthropic/Sonnet default; OpenAI, DeepSeek, xAI, and custom model IDs are user-selected | Settings |
| LLM approved preview payload | Potentially sensitive | Not persisted by default | Yes, only after explicit user send | Built from visible redacted preview | User can cancel before send |
| Generated command | Potentially risky | Not persisted by default | No | Rendered in Command Intelligence result | Insert or explicit run only |
| Sparkle update check | Low | Sparkle preferences and cache as needed by framework | Yes, to the appcast URL and GitHub release asset URLs | Automatic checks and automatic install enabled; Sparkle system profiling disabled | Software Updates settings |
| Workspace session layout | Low to medium | Application Support `session-v1.json` | No | Restores pane layout as fresh shells | Reset saved session |
| Recent directories | Medium | Application Support `recent-directories-v1.json` | No | Stores normalized recent directories | Reset saved session |
| Spotlight workspace metadata | Low to medium | macOS Spotlight index when enabled by a future release | No network exit, but visible to system search | Disabled in 1.0.6; metadata-only foundation exists but no release toggle is exposed | No visible toggle in this release |
| Notification content | Low by default | macOS notification system when enabled by a future release | No network exit, but visible in system UI | Disabled in 1.0.6; app does not request permission or post local alerts | Permission status check only |
| Menu bar status | Low | Not persisted as content | No | Staged but not part of the 1.0.6 release surface; terminal workspace remains primary | No visible toggle in this release |
| System metrics snapshot | Low | In memory only | No | Local sampling only | None beyond app use |
| Visual install seed | Low to medium | Local `@AppStorage` random UUID | No | Generated locally for procedural appearance; not a hardware identifier or credential | Reset appearance/settings behavior |
| Performance evidence | Low if sanitized | `.planning/phases/*/evidence` | Committed to repo | Synthetic markers and process samples only | Developer workflow |
| App privacy manifest | Low | Staged app bundle `PrivacyInfo.xcprivacy` | Submitted only with an App Store build | Declares no tracking and required-reason API categories | Release workflow |

## Data That Must Not Be Persisted

The app must not persist these by default:

- API key values outside Keychain.
- Shell history.
- Terminal transcripts.
- Raw selected terminal output.
- Raw LLM prompts or failed-command context.
- Provider responses.
- Generated commands.
- Environment variables.
- SSH keys or Keychain data.
- Full command output in workspace snapshots, Spotlight, notifications, menu bar, performance evidence, or release docs.

## Device Exit Points

| Exit point | Data allowed | Guardrail |
| --- | --- | --- |
| Anthropic provider request | Redacted `ApprovedCommandContextPayload` only | Explicit user send after preview |
| OpenAI provider request | Redacted `ApprovedCommandContextPayload` only | Explicit user send after preview |
| DeepSeek provider request | Redacted `ApprovedCommandContextPayload` only | Explicit user send after preview |
| xAI provider request | Redacted `ApprovedCommandContextPayload` only | Explicit user send after preview |
| Sparkle appcast/update download | Version/update request and release asset download | Automatic update settings; system profiling disabled |
| macOS Spotlight | Workspace ID, display label, directory basename | Disabled in 1.0.6; metadata-only adapter is staged for a future release |
| macOS notifications | Sanitized title/body such as `gridOS work finished` | Disabled in 1.0.6; app checks permission state only |
| Git/repo evidence | Synthetic markers, summary status, non-secret metadata | Source and evidence privacy scans |

## User Controls

- Command Intelligence send can be cancelled before any provider request.
- Provider API keys can be saved or deleted from Command Intelligence settings.
- Automatic update checks and automatic installs can be changed in Software Updates settings.
- Notifications are disabled in the release surface.
- Workspace metadata indexing is disabled in the release surface.
- Saved session/recent-directory state can be reset.
- Menu bar controls are staged for a future release.

## Verification Gates

```sh
rg 'Provider API key|LLM approved preview payload|Spotlight workspace metadata|Performance evidence' docs/privacy-data-inventory.md
rg 'kSecClassGenericPassword|kSecAttrAccessibleWhenUnlockedThisDeviceOnly|kSecUseDataProtectionKeychain' Sources/GridOSKit Tests/GridOSKitTests Sources/CommandIntelligence Tests/CommandIntelligenceTests
rg 'WorkspaceSearchMetadata|Terminal output and command history are never indexed|gridOS work finished' Sources/Integrations Tests/IntegrationsTests
rg 'NSPrivacyTracking|NSPrivacyAccessedAPICategoryUserDefaults|NSPrivacyAccessedAPICategoryDiskSpace' Sources/GridOSApp/PrivacyInfo.xcprivacy
git diff --check
```
