# gridOS Privacy Data Inventory

## Data Inventory

| Data class | Sensitivity | Stored where | Leaves device? | Default behavior | User control |
| --- | --- | --- | --- | --- | --- |
| Provider API key | Secret | Keychain generic-password item through `GridOSKit.KeychainCredentialStore` | No, except as provider auth header during explicit request | Not configured by default | Save/delete in Command Intelligence settings |
| Provider/model preference | Low | `@AppStorage` keys in `GridOSAppPreferences` | No | Anthropic/model defaults only | Settings |
| LLM approved preview payload | Potentially sensitive | Not persisted by default | Yes, only after explicit user send | Built from visible redacted preview | User can cancel before send |
| Generated command | Potentially risky | Not persisted by default | No | Rendered in Command Intelligence result | Insert or explicit run only |
| Workspace session layout | Low to medium | Application Support `session-v1.json` | No | Restores pane layout as fresh shells | Reset saved session |
| Recent directories | Medium | Application Support `recent-directories-v1.json` | No | Stores normalized recent directories | Reset saved session |
| Spotlight workspace metadata | Low to medium | macOS Spotlight index | No network exit, but visible to system search | Off by default | `Index saved workspace metadata` toggle |
| Notification content | Low by default | macOS notification system | No network exit, but visible in system UI | Off until permission/action | `Enable Notifications` flow |
| Menu bar status | Low | Not persisted as content | No | Shows compact host/workspace status | `Show Menu Bar Extra` toggle |
| System metrics snapshot | Low | In memory only | No | Local sampling only | None beyond app use |
| Visual install seed | Medium | `@AppStorage` install seed today | No | Generated locally for procedural identity | Reset appearance/settings behavior |
| Performance evidence | Low if sanitized | `.planning/phases/*/evidence` | Committed to repo | Synthetic markers and process samples only | Developer workflow |

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
| macOS Spotlight | Workspace ID, display label, directory basename | Off by default, metadata-only adapter |
| macOS notifications | Sanitized title/body such as `gridOS work finished` | Explicit permission/action |
| Git/repo evidence | Synthetic markers, summary status, non-secret metadata | Source and evidence privacy scans |

## User Controls

- Command Intelligence send can be cancelled before any provider request.
- Provider API keys can be saved or deleted from Command Intelligence settings.
- Notifications require explicit enablement.
- Workspace metadata indexing is off by default and toggle-controlled.
- Saved session/recent-directory state can be reset.
- Menu bar extra visibility is toggle-controlled.

## Verification Gates

```sh
rg 'Provider API key|LLM approved preview payload|Spotlight workspace metadata|Performance evidence' docs/privacy-data-inventory.md
rg 'kSecClassGenericPassword|kSecAttrAccessibleWhenUnlockedThisDeviceOnly|kSecUseDataProtectionKeychain' Sources/GridOSKit Tests/GridOSKitTests Sources/CommandIntelligence Tests/CommandIntelligenceTests
rg 'WorkspaceSearchMetadata|Terminal output and command history are never indexed|gridOS work finished' Sources/Integrations Tests/IntegrationsTests
git diff --check
```
