# Phase 06: llm-command-palette - Research

**Researched:** 2026-05-20
**Domain:** Native macOS SwiftUI command palette, LLM provider abstraction, Keychain credential storage, terminal command safety
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### Command Palette Shape
- **D-01:** `Command-K` opens a compact command-intelligence palette/sheet over the existing app frame. The terminal remains visible behind or around it, and closing the palette must return focus to the terminal.
- **D-02:** The palette should expose three Phase 6 flows: suggest a command from natural language, explain selected/pasted terminal output, and explain/fix a failed command. These are user-invoked actions only.
- **D-03:** Do not ship conversational shell mode or a persistent agent chat surface in Phase 6. A one-shot request/response palette is enough for the first safe command-intelligence layer.
- **D-04:** `Command-K` may supersede the current `Command-K` terminal clear shortcut, but only if the clear command remains available through an explicit Terminal menu item and a non-conflicting shortcut. Terminal correctness and discoverability must be preserved.

### Provider and Key Setup
- **D-05:** Implement `CommandIntelligence` as the provider, context-packing, redaction, and command-safety boundary. `GridOSApp` composes the UI; provider details must not leak into terminal or app-frame code.
- **D-06:** Build a provider abstraction first. If Phase 6 implements one live hosted provider, default to Anthropic/Claude because the product vision references Claude and command-palette help; keep OpenAI and local providers as protocol-ready future adapters unless planning finds a tiny safe path.
- **D-07:** API key setup is opt-in and stored in Keychain. The app remains fully usable without a configured provider and should show a calm setup/disabled state instead of errors.
- **D-08:** Do not log API keys, prompts, context payloads, generated commands, selected output, shell history, or provider responses by default. A user-enabled audit log is deferred.

### Context Visibility and Redaction
- **D-09:** No shell context leaves the machine unless the user explicitly invokes an LLM action and confirms the request context.
- **D-10:** Before each request, show a concise context preview that includes what will be sent: user prompt, working directory, selected or pasted output if present, recent failed command context if available, and redactions applied. The user can cancel before any network request.
- **D-11:** Context packing should start minimal. Include only the fields needed for the selected flow; do not send full shell history, environment variables, process lists, hidden files, SSH config, Keychain data, or metrics snapshots by default.
- **D-12:** Redaction is required before provider submission. Cover obvious secrets such as API keys, bearer/basic tokens, private key blocks, password assignments, common `.env` values, and credential-looking URLs. Redactions should be visible in the preview.
- **D-13:** Selected-output and failed-command flows should prefer explicit terminal selection or user-pasted text. If SwiftTerm does not expose reliable selected text or scrollback APIs, provide a manual paste/fallback path rather than adding invisible shell hooks.

### Suggested Command and Safety Flow
- **D-14:** Suggested command responses must show the command, plain-language explanation, working directory assumption, context used, and a risk label before any insert/run action.
- **D-15:** Default generated-command handling is insert-first. The primary safe action is to insert the command into the terminal for user inspection/editing.
- **D-16:** A direct Run action may exist only after an explicit user choice. High-risk or unknown-risk commands require a visually distinct confirmation step and should prefer insert-only unless the user confirms the exact command.
- **D-17:** Risk classification must conservatively flag destructive filesystem operations, credential/keychain access, privilege escalation, process killing, network transfer piped into shell, package-manager install scripts, and commands that mutate remote services. Unknowns should bias toward higher risk.
- **D-18:** The app must never execute a generated command automatically as a side effect of receiving a model response.

### Explain and Failed-Command Help
- **D-19:** Explain-output is a read-only assistance flow. It should explain what the selected or pasted terminal output means, likely cause, and possible next checks without mutating the shell.
- **D-20:** Failed-command help is also user-invoked. Phase 6 should not require always-on shell instrumentation; it may use selected/pasted output, current working directory, and any safe terminal metadata the app already has.
- **D-21:** Fix suggestions should follow the same command safety policy as normal suggested commands: explanation first, insert/run choices second, stronger confirmation for risky commands.

### Failure States and Offline Behavior
- **D-22:** Failure copy must be human-readable and product-level: no provider key configured, cancelled before send, offline/network failure, provider rate limit, provider error, redaction blocked request, and unsupported terminal selection should each have a clear path forward.
- **D-23:** LLM failures must not affect shell availability, terminal focus, metrics, or visual rendering. The terminal remains the product's reliable center.

### Verification Direction
- **D-24:** Plan for model/unit tests around provider protocol behavior, Keychain credential storage abstraction, context redaction, risk classification, context preview construction, and no-key/offline failure states.
- **D-25:** Plan for app smoke verification that `Command-K` opens/closes the palette, returns terminal focus, and generated command insertion does not execute until the user explicitly chooses to run.

### Claude's Discretion
- Exact palette layout, copy tone, iconography, and animation are left to planning/implementation, constrained by the terminal-first cockpit and current aesthetic modes.
- Exact provider protocol method names and request/response models are left to research/planning, constrained by testability and provider isolation.
- Exact Keychain wrapper shape is left to research/planning, constrained by not leaking secrets into logs or user defaults.
- Exact risk classifier taxonomy can be refined during planning, as long as it is conservative and testable.

### Deferred Ideas (OUT OF SCOPE)
- Conversational shell mode / REPL where the model executes multi-step tasks belongs to a later phase.
- Always-on command monitoring, shell-history indexing, and automatic failed-command detection are deferred unless planning proves a safe tiny path.
- Audit logging of prompts/context/generated commands is deferred until a user-controlled data model exists.
- Local model provider implementation is deferred unless research finds a trivial protocol adapter; the abstraction should leave room for it.
- Plugin providers, marketplace providers, public extension APIs, and user-authored command intelligence integrations are deferred.
- Menu bar/Notification Center LLM affordances belong to the macOS integrations phase.
- Full security threat modeling and hardened-runtime compatibility proof remain Phase 10 and later release-readiness work.
</user_constraints>

## Summary

Phase 6 should be planned as a narrow, opt-in command intelligence layer around the existing terminal, not as an agent runtime. The durable boundary belongs in `CommandIntelligence`: provider contracts, request/response models, redaction, context preview construction, failure states, and deterministic risk classification. `GridOSApp` should own only presentation and flow state. `TerminalCore` should expose a small controller API for selection, insertion, run, and focus restoration so the app never imports SwiftTerm directly.

Use Anthropic's direct Messages API as the first live hosted provider. Do not add an unofficial Swift SDK; the API is REST/JSON, the app already has Foundation, and avoiding a dependency keeps the phase easier to review. Use structured outputs for suggested command and fix responses, but treat provider risk labels as advisory only. The app's deterministic classifier must be the authority for insert/run gating.

Keychain storage needs a protocol first and a Security.framework-backed implementation second. Tests should use an in-memory credential store and mocked providers. The no-key path is a normal disabled state, and all shell context must pass through preview and redaction before a network request is created.

**Primary recommendation:** Implement `CommandIntelligence` first as pure Swift models/services with XCTest coverage, then wire a compact `Command-K` overlay to it through `GridOSApp` and a narrow `TerminalCore.TerminalInteractionController`.

## Standard Stack

### Core

| Library/API | Version | Purpose | Why Standard |
|-------------|---------|---------|--------------|
| SwiftUI + AppKit | macOS 14 minimum, built with Xcode 26.5 / Swift 6.3.2 locally | Palette UI, Settings, commands, focus restoration, modal confirmation | Existing app stack; native command menus and window focus behavior are already SwiftUI/AppKit |
| `CommandIntelligence` framework | Existing scaffold | Provider abstraction, context packing, redaction, risk policy, failure states | Existing architecture reserves this exact boundary and prevents provider details leaking into app/terminal code |
| `TerminalCore` + SwiftTerm | SwiftTerm `1.13.0` | Real terminal, selected text, insertion, run, focus | Existing terminal backend; SwiftTerm exposes public `selectionActive` and `getSelection()` on `AppleTerminalView`/`TerminalView` |
| Security.framework Keychain Services | OS-provided | Store Anthropic API key | Apple-supported secret storage; avoids `UserDefaults`, files, and logs for provider secrets |
| Foundation `URLSession` + `Codable` | OS-provided | Anthropic REST calls and JSON encoding/decoding | No unofficial Swift SDK required; keeps request shaping testable through protocol mocks |
| Anthropic Messages API | API version header `2023-06-01`; default model `claude-sonnet-4-6` | First live hosted LLM provider | Official direct API supports `POST /v1/messages`, API-key auth, structured outputs, request IDs, and rate-limit/error handling |

### Supporting

| Library/API | Version | Purpose | When to Use |
|-------------|---------|---------|-------------|
| Anthropic structured outputs | GA on current Claude API for supported 4.5+ and 4.6+ models | Schema-shaped JSON for suggested command/fix/explain responses | Use for provider responses that need command/explanation arrays; still validate decoded payload locally |
| Swift `Regex` / `NSRegularExpression` | Swift 6 / Foundation | Secret redaction and coarse command-risk pattern matching | Use for deterministic, testable local safety checks; keep patterns small and fixture-driven |
| XCTest | Existing Xcode scheme | Unit tests for redactor, risk classifier, credential store abstraction, provider mapping, preview models | Add `CommandIntelligenceTests` to `project.yml` and to the `gridOS` scheme |
| macOS smoke through `--cmd` | Existing debug app launch path | Prove palette open/close, focus restoration, and insertion without execution | Reuse the release doc's startup command pattern and previous focus-smoke style |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `URLSession` direct Anthropic provider | Unofficial Anthropic Swift package | No clear project-standard SDK; an extra dependency would add review surface for a small REST integration |
| Deterministic risk classifier | Ask the model to classify command risk | Model output is useful explanation context but cannot be the safety authority for terminal execution |
| Keychain Services | `@AppStorage` / `UserDefaults` | UserDefaults is not secret storage and would violate the phase context |
| TerminalCore controller API | Import SwiftTerm in `GridOSApp` | Violates module boundary and makes later terminal backend replacement harder |
| Automatic scrollback/history context | Shell hooks or background monitoring | Violates explicit user-invoked context policy and expands privacy risk |

**Installation:**

No new package should be added for Phase 6. Update `project.yml` only to add `CommandIntelligenceTests` and any new source files, then run:

```bash
xcodegen generate --use-cache
```

**Version verification:**

| Item | Verified Command/Source | Result |
|------|-------------------------|--------|
| Xcode | `xcodebuild -version` | Xcode 26.5, build 17F42 |
| Swift | `swift --version` | Apple Swift 6.3.2, arm64 macOS target |
| XcodeGen | `xcodegen --version` | 2.45.3 |
| SwiftTerm | `project.yml`, `xcodebuild -list`, `git ls-remote --tags`, local package checkout | `1.13.0`; remote tag `v1.13.0`; tag commit date 2026-03-27 |
| Anthropic API | Official docs checked 2026-05-20 | REST base `https://api.anthropic.com`; Messages API `POST /v1/messages`; required `anthropic-version` header example `2023-06-01`; current 4.6 IDs are pinned snapshots |

## Architecture Patterns

### Recommended Project Structure

```text
Sources/
├── CommandIntelligence/
│   ├── CommandIntelligenceStatus.swift
│   ├── CommandIntelligenceModels.swift        # flow/request/response/failure/risk value types
│   ├── CommandContextPreview.swift            # preview + redaction result models
│   ├── CommandContextBuilder.swift            # minimal context packing
│   ├── SecretRedactor.swift                   # deterministic redaction pass
│   ├── CommandRiskClassifier.swift            # deterministic policy
│   ├── CommandCredentialStore.swift           # protocol + in-memory store
│   ├── KeychainCommandCredentialStore.swift   # Security.framework implementation
│   ├── LLMCommandProvider.swift               # provider protocol
│   └── AnthropicCommandProvider.swift         # URLSession/Codable adapter
├── TerminalCore/
│   ├── TerminalInteractionController.swift    # selected text, insert/run, focus
│   ├── TerminalCommandCenter.swift            # existing menu commands
│   └── TerminalSurface.swift                  # attaches controller to SwiftTerm view
└── GridOSApp/
    ├── GridOSApp.swift                        # Command-K, Clear moved to non-conflicting shortcut
    ├── RootView.swift                         # owns palette overlay + terminal controller
    ├── CommandPaletteView.swift               # one-shot palette UI
    └── SettingsView.swift                     # provider/key setup, non-secret provider prefs

Tests/
├── CommandIntelligenceTests/
│   ├── SecretRedactorTests.swift
│   ├── CommandRiskClassifierTests.swift
│   ├── CommandContextPreviewTests.swift
│   ├── CommandCredentialStoreTests.swift
│   ├── AnthropicCommandProviderTests.swift
│   └── CommandIntelligenceFailureTests.swift
└── TerminalCoreTests/
    └── TerminalInteractionControllerTests.swift # if pure seams are introduced
```

### Pattern 1: CommandIntelligence Owns Pure Safety and Provider Logic

**What:** Keep provider details, redaction, preview packing, risk classification, and user-facing failure models in `CommandIntelligence`. It may depend on `GridOSKit`; it should not import `TerminalCore`, `RenderCore`, or `SystemMetrics`.

**When to use:** Every LLM request flow. `GridOSApp` should pass explicit user input and safe terminal metadata into `CommandIntelligence`, receive models back, and render them.

**Example:**

```swift
public enum CommandIntelligenceFlow: String, Sendable, Codable {
    case suggestCommand
    case explainOutput
    case failedCommandHelp
}

public struct CommandAssistanceInput: Equatable, Sendable {
    public var flow: CommandIntelligenceFlow
    public var userPrompt: String
    public var workingDirectory: String?
    public var selectedOrPastedOutput: String?
    public var failedCommand: String?
    public var failedCommandOutput: String?
}

public protocol LLMCommandProvider: Sendable {
    var providerID: LLMProviderID { get }
    func complete(_ request: LLMCommandRequest, apiKey: String) async throws -> LLMCommandResponse
}
```

### Pattern 2: Preview Before Provider Request

**What:** Build the preview from redacted context before any network request object is sent. The preview is the approval artifact; the provider receives only an approved preview payload.

**When to use:** Suggested command, explain output, and failed command help.

**Example:**

```swift
public struct CommandContextPreview: Equatable, Sendable {
    public var flow: CommandIntelligenceFlow
    public var userPrompt: String
    public var workingDirectory: String?
    public var contextBlocks: [CommandContextBlock]
    public var redactions: [RedactionFinding]
    public var blockedReasons: [String]

    public var canSend: Bool { blockedReasons.isEmpty }
}
```

Planner guidance:

- Task 1 should make preview creation pure and unit-tested.
- Preview should include character counts and redaction labels, not hidden raw context.
- There should be no code path from palette submit to provider without an approved preview object.

### Pattern 3: Keychain Store Behind a Protocol

**What:** Define `CommandCredentialStore` in `CommandIntelligence`; implement an in-memory store for tests and `KeychainCommandCredentialStore` for production.

**When to use:** Provider API key save/read/delete and no-key state.

**Example:**

```swift
public protocol CommandCredentialStore: Sendable {
    func apiKey(for provider: LLMProviderID) async throws -> String?
    func saveAPIKey(_ apiKey: String, for provider: LLMProviderID) async throws
    func deleteAPIKey(for provider: LLMProviderID) async throws
}
```

Keychain implementation details:

- Use `kSecClassGenericPassword`.
- Use service `com.aaldere1.gridos.command-intelligence`.
- Use account equal to the provider ID, for example `anthropic`.
- Set `kSecUseDataProtectionKeychain: true` when using `kSecAttrAccessible` on macOS.
- Use `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` for provider API keys.
- Use `SecItemUpdate` when an item exists; do not accumulate duplicate keys.
- Do not call `SecItemCopyMatching` on the main actor for UI reads; Apple's docs note it can block.
- Expose configured/not-configured state without returning the secret to SwiftUI unless the user is saving/replacing it.

### Pattern 4: TerminalCore Controller, Not SwiftTerm Leakage

**What:** Add a `TerminalInteractionController` owned by `TerminalCore`. `RootView` creates it, passes it to `TerminalSurface`, and palette actions call controller methods.

**When to use:** Read selected text, insert generated command, run an explicitly confirmed command, and restore focus after palette dismissal.

**Example:**

```swift
@MainActor
public final class TerminalInteractionController: ObservableObject {
    fileprivate weak var terminalView: LocalProcessTerminalView?

    public func selectedText() -> String? {
        terminalView?.getSelection()
    }

    public func insert(_ text: String) {
        terminalView?.sendText(text)
    }

    public func run(_ command: String) {
        terminalView?.sendText(command + "\n")
    }

    public func focusTerminal() {
        guard let terminalView else { return }
        terminalView.window?.makeFirstResponder(terminalView)
    }
}
```

The public API must not expose `LocalProcessTerminalView` or SwiftTerm types. The current SwiftTerm checkout has public `getSelection()` and `selectionActive`, so selected-output support can be implemented without touching the clipboard. Do not use `copy(_:)` to harvest selected text because it overwrites the user's clipboard.

### Pattern 5: Provider Response Is Structured, Local Policy Is Authoritative

**What:** Ask Anthropic for structured JSON with commands/explanations/assumptions, then decode and locally reclassify every generated command. Treat provider-supplied risk as display context only.

**When to use:** Suggested command and failed-command fix flows.

**Example schema shape:**

```json
{
  "type": "object",
  "properties": {
    "summary": { "type": "string" },
    "commands": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "command": { "type": "string" },
          "explanation": { "type": "string" },
          "workingDirectoryAssumption": { "type": "string" },
          "providerRiskLabel": { "type": "string" }
        },
        "required": ["command", "explanation", "workingDirectoryAssumption", "providerRiskLabel"],
        "additionalProperties": false
      }
    }
  },
  "required": ["summary", "commands"],
  "additionalProperties": false
}
```

Anthropic structured outputs reduce JSON parse failures, but their docs still list refusal and max-token cases where schema output may not match. Plan explicit `invalidProviderResponse`, `providerRefusal`, and `truncatedResponse` failures.

### Anti-Patterns to Avoid

- **Do not put provider logic in SwiftUI views:** Views should render models and call a service. This keeps tests in `CommandIntelligenceTests`.
- **Do not let `GridOSApp` import SwiftTerm:** Use `TerminalCore` APIs only.
- **Do not send full scrollback/history by default:** Only send explicit prompt, cwd, selected/pasted output, and failed-command text supplied by the user or safe existing metadata.
- **Do not store keys in `@AppStorage`:** Store only non-secret provider preference values in app storage.
- **Do not execute provider commands on receipt:** The only execution path is user action -> risk policy -> confirmation if needed -> `TerminalInteractionController.run`.
- **Do not use model classification as the execution gate:** The local deterministic classifier must decide confirmation and run availability.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Secret persistence | Files, `UserDefaults`, custom encryption | Security.framework Keychain Services | Apple-supported secret storage; avoids inventing credential protection |
| Terminal selection/insertion | Direct SwiftTerm calls in app code | `TerminalCore.TerminalInteractionController` | Preserves module boundary and backend replaceability |
| Shell execution | `Process`, `/bin/sh -c`, background execution | Insert/run through the active terminal only | User sees and controls command in the same shell context |
| Shell history capture | Shell hooks, prompt injection, scrollback scraping | Explicit selected text or paste fields | Avoids invisible context collection |
| Command safety authority | LLM self-assessment | Deterministic local classifier + confirmation policy | Safety must be explainable and unit-testable |
| JSON parsing recovery | Prompt-only "please output JSON" assumptions | Anthropic structured outputs plus local validation | Official feature reduces malformed responses but still needs error paths |
| Logging/debug audit | Ad hoc prompt/response logs | No default logs in Phase 6 | Audit logging is explicitly deferred and would need a user-controlled data model |

**Key insight:** Phase 6 earns trust by being deliberately less capable than an autonomous terminal agent. The safest architecture is explicit request, visible context, local redaction, provider response, local risk gate, and user-controlled insertion/run.

## Common Pitfalls

### Pitfall 1: `Command-K` Steals Clear Without Replacement

**What goes wrong:** The existing Terminal menu uses `Command-K` for Clear. Reusing it for the palette removes a common terminal action.

**Why it happens:** SwiftUI keyboard shortcuts resolve globally through window/main-window/commands, and duplicate shortcuts can be won by whichever control resolves first.

**How to avoid:** Move Terminal Clear to a visible Terminal menu item with a non-conflicting shortcut such as `Command-Option-K`; add `CommandIntelligenceCommands` using `Command-K` for the palette.

**Warning signs:** `rg 'keyboardShortcut\("k"' Sources/GridOSApp` shows more than one `Command-K`, or Clear disappears from the Terminal menu.

### Pitfall 2: Palette Dismissal Leaves Terminal Unfocused

**What goes wrong:** User closes the palette and typed shell input goes nowhere or into a hidden control.

**Why it happens:** The palette's text field becomes first responder and SwiftUI does not automatically restore AppKit first responder to the SwiftTerm view.

**How to avoid:** `RootView` should own `TerminalInteractionController`; every palette dismissal path calls `focusTerminal()` on the main actor. Smoke test this with real typing after open/close.

**Warning signs:** Focus smoke can open palette but cannot create a file through terminal input after dismissal.

### Pitfall 3: Keychain Calls Freeze UI

**What goes wrong:** Settings or palette stalls while reading credentials.

**Why it happens:** `SecItemCopyMatching` can block the calling thread.

**How to avoid:** Make credential store methods `async`; call Keychain from a store/service layer, not directly in a SwiftUI body or synchronous button render path.

**Warning signs:** Credential state is read in `body`, or keychain query dictionaries appear in `SettingsView.swift`.

### Pitfall 4: Redaction Happens After Preview

**What goes wrong:** The preview shows safe-looking content, but raw data is sent to the provider.

**Why it happens:** Preview and provider payload are built independently.

**How to avoid:** Build one redacted preview payload and send exactly that approved payload. The approved object should contain redacted strings only.

**Warning signs:** Separate `buildPreview` and `buildProviderRequest` code paths repeat context extraction.

### Pitfall 5: Risk Classifier Tries to Be a Full Shell Parser

**What goes wrong:** The classifier becomes brittle, misses shell edge cases, or blocks harmless commands unpredictably.

**Why it happens:** POSIX shell syntax, zsh expansions, pipes, command substitutions, aliases, and scripts are too broad for a small phase.

**How to avoid:** Use conservative pattern rules. If a command contains shell metacharacters or unknown constructs that prevent confident classification, label it `unknown` and require the stronger gate.

**Warning signs:** Classifier tests assert detailed AST behavior, or a "safe" label is used to skip user confirmation entirely.

### Pitfall 6: Provider Errors Leak Technical Jargon

**What goes wrong:** Users see raw HTTP, JSON, or `URLError` strings.

**Why it happens:** Provider errors bubble directly to SwiftUI.

**How to avoid:** Map provider/network/parser failures into `CommandIntelligenceFailure` with title, message, recovery action, and optional request ID.

**Warning signs:** UI copy includes raw enum/debug strings like `decodingError`, `NSURLErrorDomain`, or `status 429`.

## Code Examples

Verified patterns from official sources and local source inspection.

### Anthropic Messages Request Shape

```swift
struct AnthropicMessageRequest: Encodable {
    var model: String
    var maxTokens: Int
    var system: String
    var messages: [AnthropicMessage]
    var outputConfig: AnthropicOutputConfig?

    enum CodingKeys: String, CodingKey {
        case model
        case maxTokens = "max_tokens"
        case system
        case messages
        case outputConfig = "output_config"
    }
}

var request = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
request.httpMethod = "POST"
request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
request.setValue("application/json", forHTTPHeaderField: "content-type")
```

Source: Anthropic API overview and Messages API docs.

### Keychain Generic Password Query

```swift
let query: [String: Any] = [
    kSecClass as String: kSecClassGenericPassword,
    kSecAttrService as String: "com.aaldere1.gridos.command-intelligence",
    kSecAttrAccount as String: provider.rawValue,
    kSecUseDataProtectionKeychain as String: true,
    kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
    kSecValueData as String: Data(apiKey.utf8)
]

let status = SecItemAdd(query as CFDictionary, nil)
```

Source: Apple Keychain Services, `SecItemAdd`, `kSecAttrAccessible`, and restricting keychain item accessibility docs.

### Conservative Risk Rules

```swift
public struct CommandRiskClassifier: Sendable {
    public func classify(_ command: String) -> CommandRiskAssessment {
        let normalized = command.trimmingCharacters(in: .whitespacesAndNewlines)

        if normalized.isEmpty {
            return .unknown(reason: "Empty command")
        }

        if containsNetworkPipeToShell(normalized) {
            return .high(reason: "Downloads code and executes it in a shell")
        }

        if matchesAny(normalized, highRiskPatterns) {
            return .high(reason: "Can change files, credentials, processes, privileges, or remote services")
        }

        if containsShellExpansionOrChaining(normalized) {
            return .unknown(reason: "Shell expansion or command chaining needs manual review")
        }

        if matchesAny(normalized, mutatingPatterns) {
            return .medium(reason: "Changes local project or package state")
        }

        return .low(reason: "No known mutation pattern detected")
    }
}
```

Planner guidance: make the first classifier fixture-driven and intentionally conservative. Unknown is not a failure; it is a stronger gate.

### TerminalCore Insertion and Selection

```swift
@MainActor
public final class TerminalInteractionController: ObservableObject {
    fileprivate weak var terminalView: LocalProcessTerminalView?

    public func selectedText() -> String? {
        terminalView?.getSelection()
    }

    public func insert(_ command: String) {
        terminalView?.sendText(command)
    }

    public func run(_ command: String) {
        terminalView?.sendText(command + "\n")
    }
}
```

Source: local SwiftTerm checkout exposes `public func getSelection() -> String?` and the current `TerminalSurface.swift` already has a private `sendText(_:)` helper for startup commands.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Prompt-only JSON formatting | Anthropic `output_config.format` structured outputs | GA expanded across Claude API in 2026 docs | Use schema-shaped provider responses, but still handle refusals and max-token truncation |
| Dated Claude model IDs for all releases | 4.6-generation IDs use dateless pinned IDs like `claude-sonnet-4-6` | Anthropic 4.6 generation docs | `claude-sonnet-4-6` is a fixed model snapshot, not an evergreen alias |
| Assistant prefill for response shaping | Structured outputs/system prompt instructions for newer models | Anthropic docs note prefill unsupported on newer 4.6/4.7 models | Do not rely on assistant prefill to force JSON |
| `Command-K` as terminal Clear | `Command-K` for command palette; Clear moved | Phase 6 decision | Preserve clear through menu and new shortcut |

**Deprecated/outdated:**

- Assistant prefill as a JSON forcing mechanism: current Anthropic docs point to structured outputs for newer models.
- Direct provider result execution: out of scope and unsafe for Phase 6.
- Shell-history indexing for context: deferred and contrary to explicit context preview requirements.

## Open Questions

1. **Should Phase 6 implement direct Run for high-risk commands or make high-risk insert-only?**
   - What we know: D-16 allows direct Run only after explicit choice and requires stronger confirmation for high/unknown risk.
   - What's unclear: Whether the alpha UX should include exact-command confirmation now or punt high-risk execution to insert-only.
   - Recommendation: Plan low-risk Run, medium/high/unknown confirmation policy in models, and make high/unknown default to insert-only unless a plan explicitly adds exact-command confirmation.

2. **How much selected-output support is needed in the first plan wave?**
   - What we know: SwiftTerm has public `getSelection()`, but context decisions allow a paste fallback.
   - What's unclear: Whether selection behavior remains stable across alternate screen/TUI apps and fast output.
   - Recommendation: Implement `selectedText()` through `TerminalInteractionController`, show paste fallback when nil/empty, and include manual smoke for selected output.

3. **Should Anthropic model be user-selectable in Phase 6?**
   - What we know: Default should be Anthropic/Claude if one hosted provider ships. Current docs identify `claude-sonnet-4-6` as a pinned ID and Opus 4.7 as newer for complex reasoning.
   - What's unclear: Product preference for cost/capability and whether users need advanced provider settings.
   - Recommendation: Store non-secret provider ID and model ID in app preferences with default `claude-sonnet-4-6`; keep UI simple and avoid exposing model complexity unless needed.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Xcode | Build/test macOS app | yes | 26.5 / build 17F42 | None |
| Swift | Swift 6 code/tests | yes | Apple Swift 6.3.2 | None |
| XcodeGen | Regenerate project after target changes | yes | 2.45.3 | Manual Xcode project edits are not recommended |
| SwiftTerm | Terminal selection/insert/focus through TerminalCore | yes | 1.13.0 | Manual paste fallback for selected output if API fails |
| Security.framework / `security` tool | Keychain implementation and local inspection | yes | OS-provided, `/usr/bin/security` present | In-memory store for unit tests only |
| Anthropic API network access | Live provider requests | runtime/user-dependent | API docs current 2026-05-20 | No-key/offline disabled state; mocked provider tests |
| Anthropic API key | Live provider requests | unknown, user-configured | Not checked by design | App remains usable; Settings setup path |

**Missing dependencies with no fallback:**

- None for planning and unit-test implementation. Live provider behavior requires a user-supplied Anthropic API key, but no-key is a required non-blocking state.

**Missing dependencies with fallback:**

- Anthropic API key/network: use no-key/offline states and provider mocks for validation.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | XCTest via Xcode scheme |
| Config file | `project.yml` and generated `gridOS.xcodeproj/xcshareddata/xcschemes/gridOS.xcscheme` |
| Quick run command | `xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO build test` |
| Full suite command | `xcodegen generate --use-cache && xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO build test && git diff --check` |
| Estimated runtime | 90-180 seconds based on previous phase validation |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| LLM-01 | `Command-K` opens compact palette and Clear remains available on non-conflicting shortcut | source/smoke | `rg 'keyboardShortcut\("k", modifiers: \[\.command\]\)|Clear|CommandIntelligenceCommands' Sources/GridOSApp` plus app smoke | no, add `Sources/GridOSApp/CommandPaletteView.swift` |
| LLM-02 | Palette exposes suggest command, explain output, and failed-command help flows | unit/source | `rg 'suggestCommand|explainOutput|failedCommandHelp' Sources/CommandIntelligence Sources/GridOSApp Tests/CommandIntelligenceTests` | no, add models/tests |
| LLM-03 | No provider key is a normal disabled/setup state | unit | `xcodebuild ... -only-testing:CommandIntelligenceTests/CommandIntelligenceFailureTests` | no, add tests |
| LLM-04 | API key is stored through credential-store abstraction, not `@AppStorage` | unit/source | `rg 'CommandCredentialStore|KeychainCommandCredentialStore|kSecClassGenericPassword' Sources/CommandIntelligence Tests/CommandIntelligenceTests` and `! rg 'apiKey.*AppStorage|UserDefaults.*api' Sources` | no, add tests |
| LLM-05 | Context preview is constructed before send and includes prompt, cwd, selected/pasted/failed context, redaction list | unit | `xcodebuild ... -only-testing:CommandIntelligenceTests/CommandContextPreviewTests` | no, add tests |
| LLM-06 | Redactor masks API keys, bearer/basic tokens, private key blocks, `.env` assignments, and credential URLs | unit | `xcodebuild ... -only-testing:CommandIntelligenceTests/SecretRedactorTests` | no, add tests |
| LLM-07 | Risk classifier flags destructive filesystem, credential/keychain, sudo, process kill, network pipe to shell, package install scripts, and remote mutation | unit | `xcodebuild ... -only-testing:CommandIntelligenceTests/CommandRiskClassifierTests` | no, add tests |
| LLM-08 | Suggested command response shows command, explanation, cwd assumption, context used, local risk label, insert/run choices | unit/source | `xcodebuild ... -only-testing:CommandIntelligenceTests/CommandProviderResponseTests` plus `rg 'insert|run|risk' Sources/GridOSApp/CommandPaletteView.swift` | no, add tests |
| LLM-09 | Insert action inserts without executing; Run appends newline only after explicit user action and policy gate | unit/smoke | source checks plus manual smoke creating file only after Run, not Insert | no, add TerminalCore seam |
| LLM-10 | Explain-output and failed-command help are read-only until a fix command goes through same safety policy | unit/source | `xcodebuild ... -only-testing:CommandIntelligenceTests/CommandIntelligenceFlowTests` | no, add tests |
| LLM-11 | Human-readable failures exist for no key, cancelled, offline/network, rate limit, provider error, redaction blocked, unsupported selection | unit | `xcodebuild ... -only-testing:CommandIntelligenceTests/CommandIntelligenceFailureTests` | no, add tests |
| LLM-12 | LLM failure does not affect terminal focus/shell availability | smoke | Launch Debug app, open/close palette, cancel/no-key flow, type terminal command via focused shell | manual smoke required |

### Sampling Rate

- **Per task commit:** `xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO build test`
- **Per wave merge:** `xcodegen generate --use-cache && xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO build test && git diff --check`
- **Phase gate:** Full suite green, source checks pass, and app smoke proves `Command-K` focus restoration plus insert-before-run behavior before `/gsd:verify-work`.

### Wave 0 Gaps

- [ ] `Tests/CommandIntelligenceTests/SecretRedactorTests.swift` - covers LLM-06.
- [ ] `Tests/CommandIntelligenceTests/CommandRiskClassifierTests.swift` - covers LLM-07.
- [ ] `Tests/CommandIntelligenceTests/CommandContextPreviewTests.swift` - covers LLM-05.
- [ ] `Tests/CommandIntelligenceTests/CommandCredentialStoreTests.swift` - covers LLM-03 and LLM-04 with in-memory store.
- [ ] `Tests/CommandIntelligenceTests/CommandIntelligenceFailureTests.swift` - covers LLM-03 and LLM-11.
- [ ] `Tests/CommandIntelligenceTests/AnthropicCommandProviderTests.swift` - covers request shaping, headers, structured output decode, 401/429/5xx/invalid JSON mapping with mocked URL loading.
- [ ] `project.yml` - add `CommandIntelligenceTests` target and include it in the `gridOS` scheme test targets.
- [ ] `Sources/TerminalCore/TerminalInteractionController.swift` or equivalent seam - enables LLM-09 without SwiftTerm leakage.

### Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Palette focus restoration | LLM-01, LLM-12 | First responder behavior crosses SwiftUI/AppKit/SwiftTerm | Launch Debug app, focus terminal, press `Command-K`, close palette with Escape/cancel, type `printf 'PHASE6_FOCUS\n' > /tmp/gridos_phase6_focus.txt`, verify file exists |
| Insert does not execute | LLM-09 | Requires observing real shell behavior | Ask provider mock/live flow for `printf 'PHASE6_INSERT\n' > /tmp/gridos_phase6_insert.txt`; click Insert; verify file does not exist until user presses Return or explicit Run |
| Run confirmation gate | LLM-07, LLM-09 | Visual confirmation and exact command display need human review | Use high-risk fixture such as `rm -rf ~/tmp/gridos-test`; verify distinct confirmation or insert-only fallback appears and no execution happens on model response |
| Selected output explain fallback | LLM-02, LLM-10 | SwiftTerm selection varies by terminal state | Select visible output and open explain flow; if selected text is unavailable, verify paste fallback and unsupported-selection copy are clear |

### Recommended Source Checks

```bash
rg 'CommandIntelligenceFlow|suggestCommand|explainOutput|failedCommandHelp' Sources/CommandIntelligence Tests/CommandIntelligenceTests
rg 'SecretRedactor|RedactionFinding|private key|Bearer|Basic|credential URL' Sources/CommandIntelligence Tests/CommandIntelligenceTests
rg 'CommandRiskClassifier|network pipe|sudo|rm -rf|git push|kubectl|docker|brew install|npm install' Sources/CommandIntelligence Tests/CommandIntelligenceTests
rg 'CommandCredentialStore|KeychainCommandCredentialStore|kSecClassGenericPassword|kSecAttrAccessibleWhenUnlockedThisDeviceOnly' Sources/CommandIntelligence Tests/CommandIntelligenceTests
rg 'keyboardShortcut\("k", modifiers: \[\.command\]\)|CommandIntelligenceCommands|Clear' Sources/GridOSApp
rg 'TerminalInteractionController|getSelection|sendText|focusTerminal' Sources/TerminalCore Sources/GridOSApp
```

## Sources

### Primary (HIGH confidence)

- `06-CONTEXT.md` - locked Phase 6 decisions and deferred scope.
- `.planning/STATE.md`, `.planning/ROADMAP.md`, `.planning/PROJECT.md` - project decisions, module boundaries, Phase 6 exit criteria.
- `docs/production-roadmap.md`, `docs/security-privacy.md`, `docs/architecture.md`, `docs/release.md` - LLM deliverables, privacy/safety policy, module direction, smoke style.
- `project.yml` - target/source-of-truth and SwiftTerm dependency.
- `Sources/CommandIntelligence/CommandIntelligenceStatus.swift` - current scaffold.
- `Sources/GridOSApp/GridOSApp.swift`, `RootView.swift`, `SettingsView.swift` - command menu, app composition, settings persistence patterns.
- `Sources/TerminalCore/TerminalSurface.swift`, `TerminalCommandCenter.swift` - SwiftTerm adapter and terminal command bridge.
- Anthropic API overview - https://platform.claude.com/docs/en/api/overview - REST base, Messages API, headers, rate-limit/error framing, request limits.
- Anthropic Messages API examples - https://platform.claude.com/docs/en/build-with-claude/working-with-messages - stateless messages, basic response shape, structured-output guidance pointer.
- Anthropic structured outputs - https://platform.claude.com/docs/en/build-with-claude/structured-outputs - JSON schema output, limitations, refusals/max-token caveats.
- Anthropic model IDs/versioning - https://platform.claude.com/docs/en/about-claude/models/model-ids-and-versions - 4.6 dateless IDs as pinned snapshots.
- Apple Security / Keychain Services - https://developer.apple.com/documentation/security/keychain-services - Keychain domain.
- Apple restricting keychain item accessibility - https://developer.apple.com/documentation/Security/restricting-keychain-item-accessibility - `kSecAttrAccessible` guidance and most-restrictive-option principle.
- Apple `SecItemAdd` / `SecItemCopyMatching` / `kSecAttrAccessible` docs - official API behavior, add/update/query shape, and note that matching can block.
- Apple SwiftUI `keyboardShortcut(_:modifiers:)` - https://developer.apple.com/documentation/swiftui/view/keyboardshortcut(_:modifiers:) - shortcut target resolution and command/menu behavior.
- Local SwiftTerm checkout - `AppleTerminalView.getSelection()`, `selectionActive`, and `MacTerminalView.copy(_:)` behavior inspected.

### Secondary (MEDIUM confidence)

- OWASP Logging Cheat Sheet - https://cheatsheetseries.owasp.org/cheatsheets/Logging_Cheat_Sheet.html - sensitive data should be removed/masked/sanitized instead of logged.
- OWASP Secrets Management Cheat Sheet - https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html - API keys, credentials, SSH keys, certificates as secrets requiring lifecycle handling.

### Tertiary (LOW confidence)

- None used as authoritative input.

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH - Existing repo stack is explicit in `project.yml`; current official Anthropic/Apple docs were checked; local tool/package versions were verified.
- Architecture: HIGH - Matches repo architecture rules and inspected source seams; `CommandIntelligence` boundary is already documented.
- Pitfalls: HIGH - Derived from locked phase decisions, official API caveats, and observed SwiftUI/SwiftTerm integration points.
- Provider model default: MEDIUM - `claude-sonnet-4-6` is current and documented as pinned, but model lineup changes quickly; verify before implementation if planning is delayed.

**Research date:** 2026-05-20
**Valid until:** 2026-06-19 for local architecture and Apple APIs; 2026-05-27 for Anthropic model/provider recommendations.
