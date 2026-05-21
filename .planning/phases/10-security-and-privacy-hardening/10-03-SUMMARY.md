---
phase: 10-security-and-privacy-hardening
plan: 03
subsystem: command-intelligence-risk-policy
tags: [command-risk, run-policy, local-authority]
provides:
  - "Expanded dangerous and ambiguous command-risk fixtures"
  - "Local run-policy authority regression tests"
  - "Source proof for insert-only and confirmation UI controls"
requirements-completed: ["PHASE-10"]
duration: 4 min
completed: 2026-05-21
---

# Phase 10 Plan 03: Command-Risk and Run-Policy Hardening Summary

## Accomplishments

- Expanded command-risk fixtures for Keychain/SSH access, clipboard pipes, privileged writes, LaunchAgent loading, AppleScript automation, network pipe-to-shell, recursive chmod/chown, hard resets, inline interpreters, and encoded shell payloads.
- Added classifier handling for `launchctl`/`osascript` system automation as high risk with insert-only policy.
- Added classifier handling for encoded shell payloads and inline interpreter snippets as unknown risk with insert-only policy.
- Added a service regression proving provider `providerRiskLabel` values remain advisory and never override local `CommandRiskClassifier` policy.
- Re-verified app source gates for `localRisk.policy`, `Insert for Review`, and the exact-run confirmation alert.

## Task Commits

1. **Task 10-03-01: Expand command-risk classifier fixtures** - `e9c3175`
2. **Task 10-03-02: Prove app run controls honor local policy** - `5231861`

## Deviations from Plan

None - plan executed exactly as written.

## Verification

```sh
xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO test -only-testing:CommandIntelligenceTests/CommandRiskClassifierTests
rg 'security dump-keychain|cat ~/.ssh/id_ed25519|sudo tee /etc/hosts|base64 -d \| sh|Encoded shell payload' Tests/CommandIntelligenceTests/CommandRiskClassifierTests.swift
xcodebuild -quiet -project gridOS.xcodeproj -scheme gridOS -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO test -only-testing:CommandIntelligenceTests
rg 'security dump-keychain|cat ~/.ssh/id_ed25519|Encoded shell payload|riskClassifier.classify|localRisk.policy|Insert for Review|Run exactly this command\?' Sources/GridOSApp Sources/CommandIntelligence Tests/CommandIntelligenceTests
git diff --check
```

## Next Phase Readiness

Plan 10-04 can focus on Keychain, preference, persistence, indexing, notification, and local privacy gates with LLM request and command-run safety now covered.
