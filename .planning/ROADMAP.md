# gridOS implementation roadmap

This file is the execution-oriented companion to `docs/production-roadmap.md`.

## Phase 0 - Product, legal, and repo foundation

Status: complete

Goal: make the repo buildable, trackable, and safe to iterate on.

Exit criteria:

- Durable planning state exists.
- License posture is explicit.
- XcodeGen project scaffold exists.
- Blank app builds.
- Initial architecture/security/release docs exist.
- CI skeleton exists.

## Phase 1 - Native shell MVP

Status: complete

Goal: ship a boring but real terminal surface before visual ambition expands.

Exit criteria:

- User default shell launches in app.
- PTY lifecycle and resize handling work.
- Copy, paste, selection, clear, reset, and basic preferences exist.
- Real TUI apps are manually verified.

## Phase 2 - Metal identity MVP

Status: complete

Goal: prove the product can feel special without damaging terminal usability.

Exit criteria:

- One Metal background shader renders behind or around the terminal.
- Procedural install seed exists.
- Terminal activity can trigger subtle visual effects.
- Renderer idles responsibly.

## Phase 3 - Production app frame

Status: complete

Goal: turn the prototype into a coherent Mac app shell.

Exit criteria:

- Settings, keyboard commands, window behavior, accessibility, and state restoration are production-shaped.

## Phase 4 - Real system metrics

Status: complete

Goal: replace decorative panels with truthful instrumentation.

Exit criteria:

- CPU, memory, disk, network, battery, and thermal metrics are sampled and displayed with graceful fallback.

## Phase 5 - Aesthetic modes

Status: complete

Goal: ship multiple coherent visual identities.

Exit criteria:

- Tron, Severance, and Apple-native modes exist.
- Mode switching is fast and stable.
- Effects never obscure terminal text.

Plans: 4 plans

- [x] 05-01-PLAN.md - RenderCore/GridOSKit mode registry, tokens, preferences, and seed foundation.
- [x] 05-02-PLAN.md - AppStorage composition, Settings picker, and native Command-Shift-M mode command.
- [x] 05-03-PLAN.md - App-frame token integration and mode-aware Metal shader/motion integration.
- [x] 05-04-PLAN.md - Screenshot evidence helper, docs/state updates, and visual verification checkpoint.

## Phase 6 - LLM command palette

Status: complete

Goal: add useful command assistance without unsafe execution surprises.

Exit criteria:

- Command palette supports suggested commands, explain output, failed-command help, context preview, redaction, and confirmation gates.

Plans: 6 plans

- [x] 06-01-PLAN.md - CommandIntelligence contracts, approved-payload contract, test target, credentials, and failure copy.
- [x] 06-02-PLAN.md - Secret redaction and context preview construction.
- [x] 06-03-PLAN.md - Local risk classifier and run policy.
- [x] 06-04-PLAN.md - Anthropic provider adapter, Keychain credential storage, and Settings setup.
- [x] 06-05-PLAN.md - Command-K palette shell, TerminalCore interaction bridge, preview-before-send flow, and Settings action wiring.
- [x] 06-06-PLAN.md - Result rendering, deterministic smoke fixture, insert/run policy, docs/evidence, and final smoke checkpoint.

## Phase 7 - Multi-pane and session management

Status: complete

Goal: support real developer workflows with multiple shells.

Exit criteria:

- Split panes, session restoration, recent directories, and process cleanup are reliable.

Plans: 5 plans

- [x] 07-01-PLAN.md - TerminalCore pane and session model foundation.
- [x] 07-02-PLAN.md - Active-pane routing and process lifecycle.
- [x] 07-03-PLAN.md - Multi-pane SwiftUI workspace and native commands.
- [x] 07-04-PLAN.md - Session persistence, restore copy, recent directories, and docs.
- [x] 07-05-PLAN.md - Smoke fixture, evidence, and final verification.

## Phase 8 - macOS integrations

Status: complete

Goal: make gridOS genuinely Mac-first.

Exit criteria:

- Menu bar extra, notifications, Keychain-backed secrets, and optional indexing/preview integrations are stable.

Plans: 4 plans

- [x] 08-01-PLAN.md - Integration models, preferences, and Keychain foundation.
- [x] 08-02-PLAN.md - Menu bar extra and macOS Integrations Settings.
- [x] 08-03-PLAN.md - Local notifications and deterministic smoke.
- [x] 08-04-PLAN.md - Metadata-only indexing foundation and final evidence.

## Phase 9 - Performance hardening

Status: complete

Goal: prove the native rewrite with measurements.

Exit criteria:

- Cold start, memory, idle CPU, input latency, heavy output, and frame pacing evidence exists.

Plans: 4 plans

- [x] 09-01-PLAN.md - Benchmark harness foundation.
- [x] 09-02-PLAN.md - Deterministic benchmark app fixtures.
- [x] 09-03-PLAN.md - Benchmark scenarios and measured report.
- [x] 09-04-PLAN.md - Final evidence, docs, and phase signoff.

## Phase 10 - Security and privacy hardening

Status: in-progress

Goal: make a terminal plus LLM app trustworthy.

Exit criteria:

- Threat model, privacy inventory, redaction tests, dependency review, and hardened runtime pass are complete.

Plans: 5 plans

- [x] 10-01-PLAN.md - Threat model, privacy data inventory, and release/security doc links.
- [x] 10-02-PLAN.md - LLM context, redaction, provider-boundary, and failure privacy hardening.
- [ ] 10-03-PLAN.md - Command-risk classifier and app run-policy hardening.
- [ ] 10-04-PLAN.md - Keychain, preference, persistence, indexing, notification, and evidence privacy gates.
- [ ] 10-05-PLAN.md - Dependency/license review, hardened runtime compatibility, final evidence, and phase signoff.

## Phase 11 - Alpha

Status: pending

Goal: internal daily-driver validation.

Exit criteria:

- Signed internal builds are used for real work without terminal correctness blockers.

## Phase 12 - Beta

Status: pending

Goal: external installability and feedback.

Exit criteria:

- Developer ID signed, hardened, notarized distribution and update flow work on a clean Mac.

## Phase 13 - 1.0 release candidate

Status: pending

Goal: freeze features and prove release quality.

Exit criteria:

- Full release checklist passes with no critical or high-severity known issues.

## Phase 14 - Production launch

Status: pending

Goal: ship and operate.

Exit criteria:

- Public download, update feed, checksums, support docs, known issues, and hotfix process are live.
