# Phase 06: LLM command palette - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md - this log preserves the alternatives considered.

**Date:** 2026-05-20T17:51:37Z
**Phase:** 06-llm-command-palette
**Areas discussed:** Command palette shape, Provider and key setup, Context visibility and redaction, Suggested command and safety flow, Explain and failed-command help, Failure states

---

## Workflow Note

The interactive `request_user_input` picker was unavailable in Default mode. Following the skill adapter fallback, the recommended default was selected: discuss all core Phase 6 gray areas. Decisions were derived from the roadmap, product/security docs, prior phase context, and current codebase patterns. The user can edit `06-CONTEXT.md` before planning if any default should change.

## Discuss Scope

| Option | Description | Selected |
| --- | --- | --- |
| All core areas | Covers command UX, context visibility, provider/key setup, safety gates, and failure states. | yes |
| Safety + privacy only | Locks conservative context/redaction/confirmation policy while using roadmap defaults for UX. | no |
| Command UX first | Focuses on palette, explain, insert/run, and failed-command flow while safety follows existing docs. | no |

**Selected default:** All core areas.
**Notes:** This is the safest planning input because Phase 6 crosses UI, terminal focus, network requests, secrets, and command execution.

## Command Palette Shape

| Option | Description | Selected |
| --- | --- | --- |
| One-shot palette | `Command-K` opens a compact suggest/explain/fix surface over the app. | yes |
| Persistent chat pane | Add an always-visible assistant/chat surface. | no |
| Conversational shell mode | Let the model act through an agent-like shell REPL. | no |

**Captured decision:** Use a one-shot command-intelligence palette. Defer persistent chat and conversational shell mode.
**Notes:** This preserves the Phase 3 terminal-first cockpit and avoids agent-like behavior too early.

## Provider and Key Setup

| Option | Description | Selected |
| --- | --- | --- |
| Provider abstraction with Anthropic-first live adapter | Build the protocol boundary now, likely implement Claude first, and leave OpenAI/local for future adapters. | yes |
| Multi-provider UI in Phase 6 | Ship Anthropic, OpenAI, and local provider choices now. | no |
| No live provider yet | Build only models and mocks. | no |

**Captured decision:** Provider abstraction first, Anthropic/Claude first if a live hosted provider is implemented, API key in Keychain, no-key state is normal.
**Notes:** This follows `docs/vision.md` while avoiding provider sprawl.

## Context Visibility and Redaction

| Option | Description | Selected |
| --- | --- | --- |
| Explicit preview before send | Show context and redactions before every provider request. | yes |
| Silent minimal context | Send minimal context without an explicit preview. | no |
| Global allow-once setting | Let users approve future sends without review. | no |

**Captured decision:** Every LLM request is user-invoked and previewed before send. Minimal context only. Redaction is required.
**Notes:** This directly carries forward `docs/security-privacy.md` and the project privacy posture.

## Suggested Command and Safety Flow

| Option | Description | Selected |
| --- | --- | --- |
| Insert-first with gated run | Show command, explanation, working directory, risk label, Insert primary, Run secondary/gated. | yes |
| Run-first for low risk | Let low-risk commands run as the primary action. | no |
| Insert-only always | Never provide direct run from the palette. | no |

**Captured decision:** Insert-first. Direct run is explicit and gated; high/unknown-risk commands require stronger confirmation or insert-only fallback.
**Notes:** Generated commands are never executed automatically as a side effect of model response.

## Explain and Failed-Command Help

| Option | Description | Selected |
| --- | --- | --- |
| User-selected/pasted context | Explain selected/pasted output and failed-command text by explicit user action. | yes |
| Always-on shell instrumentation | Capture every command and exit state in the background. | no |
| Manual prompt only | User types everything without terminal selection integration. | no |

**Captured decision:** Prefer selected-output/recent-failure context when safely available, but preserve a paste fallback. No invisible shell hooks in Phase 6.
**Notes:** This makes failed-command help feasible without turning the shell into a monitored surface.

## Failure States

| Option | Description | Selected |
| --- | --- | --- |
| Human-readable product states | No key, cancelled, offline, rate-limited, provider error, redaction blocked, unsupported selection. | yes |
| Raw provider/runtime errors | Surface underlying errors mostly unchanged. | no |
| Block terminal until resolved | Treat LLM setup/failure as app-blocking. | no |

**Captured decision:** LLM failures never block terminal use and must be understandable without provider/runtime jargon.
**Notes:** The terminal remains the reliable center of the product.

## the agent's Discretion

- Exact palette layout and command copy.
- Exact provider protocol shape.
- Exact Keychain wrapper implementation.
- Exact risk classifier taxonomy, as long as it remains conservative and testable.

## Deferred Ideas

- Conversational shell mode.
- Always-on shell monitoring and command-history indexing.
- Prompt/context/generated-command audit logging.
- Full multi-provider UI.
- Local model provider implementation.
- Public command-intelligence plugin APIs.
