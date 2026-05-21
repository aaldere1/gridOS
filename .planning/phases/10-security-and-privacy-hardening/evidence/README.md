# Phase 10 security and privacy hardening

## Privacy source gates

Phase 10 keeps provider secrets in Keychain-only storage and keeps terminal/LLM private data out of preferences, persistence, Spotlight metadata, notifications, and evidence files. The source gates for this pass are:

```sh
xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO test -only-testing:GridOSKitTests -only-testing:CommandIntelligenceTests/CommandCredentialStoreTests -only-testing:TerminalCoreTests/TerminalWorkspacePersistenceTests -only-testing:IntegrationsTests
FORBIDDEN="shell""History|terminal""Transcript|environment""Variables|command""Output|selected""Output.*write|pro""mpt.*write|api""Key.*AppStorage|User""Defaults.*api|\\.""png|\\.""trace"
! rg "$FORBIDDEN" Sources .planning/phases/10-security-and-privacy-hardening/evidence
```

## Persistence proof

Workspace persistence stores layout/session metadata in `session-v1.json` and recent working directories in `recent-directories-v1.json`. Tests prove the snapshot payload omits process identifiers, terminal transcripts, shell history, environment fields, prompts, command output, and generated commands.

## Integration proof

Spotlight metadata is built through `WorkspaceSearchMetadata` and indexes the workspace display name plus directory basename only. Notifications use the sanitized default title `gridOS work finished` and body `A long-running task completed in your workspace.`

## Known limitations

The current checks prove source-level storage boundaries and deterministic test fixtures. They do not inspect a notarized runtime container or live user data, which remains a later release-candidate validation item.
