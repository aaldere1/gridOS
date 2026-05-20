# Phase 04: Real system metrics - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-20T14:54:56Z
**Phase:** 04-real-system-metrics
**Areas discussed:** Metric truth and scope, Sampling budget and backpressure, App-frame display, Privacy/reliability/user messaging

---

## Workflow Note

The Codex picker was unavailable in Default mode, so the workflow fallback selected the recommended path: discuss all Phase 4 gray areas and apply conservative defaults. These defaults are grounded in the existing roadmap, Phase 3 context, and codebase scout.

---

## Metric Truth and Scope

| Option | Description | Selected |
|--------|-------------|----------|
| Truthful native baseline | CPU, memory, disk, network, battery, thermal, and top process data sampled locally with unavailable states when needed. | ✓ |
| Decorative/status-lite metrics | Show simplified status values even when exact data is not available. | |
| Deep diagnostics | Add advanced per-process/process-management details in this phase. | |

**User's choice:** Recommended default selected by fallback.
**Notes:** Aligns with product promise and Phase 4 acceptance criteria: truthful instrumentation, no root permissions, graceful degradation.

---

## Sampling Budget and Backpressure

| Option | Description | Selected |
|--------|-------------|----------|
| Human-scannable cadence | Refresh fast-changing metrics around once per second and slower metrics less often; reduce work when not visible or constrained. | ✓ |
| Maximum freshness | Sample as frequently as possible for lively visuals. | |
| Manual refresh only | Avoid background sampling unless user requests a refresh. | |

**User's choice:** Recommended default selected by fallback.
**Notes:** Preserves the Phase 2/3 idle-renderer discipline and avoids metrics becoming the new idle CPU cost.

---

## App-Frame Display

| Option | Description | Selected |
|--------|-------------|----------|
| Terminal-first instrumentation | Compact system strip for host health and activity panel for top processes/unavailable explanations. | ✓ |
| Dashboard-forward layout | Let metrics compete with terminal space through larger charts and dense panels. | |
| Minimal hidden metrics | Keep metrics mostly tucked away to avoid layout changes. | |

**User's choice:** Recommended default selected by fallback.
**Notes:** Carries forward Phase 3 decisions that terminal work remains dominant and panels should not contain fake content.

---

## Privacy, Reliability, and User Messaging

| Option | Description | Selected |
|--------|-------------|----------|
| Local, conservative, concise | Keep snapshots local, avoid full process args initially, and show unavailable states as normal platform facts. | ✓ |
| Detailed process disclosure | Show full process paths/arguments and richer diagnostics immediately. | |
| Error-heavy transparency | Surface unavailable APIs as warning/error states. | |

**User's choice:** Recommended default selected by fallback.
**Notes:** Process details can be sensitive in a terminal app. The first production surface should be useful without exposing more than needed.

---

## the agent's Discretion

- Exact macOS API choices are left to research.
- Exact metric label formatting and panel spacing are left to planning/implementation.
- Exact refresh intervals can be tuned after measurement.

## Deferred Ideas

- Configurable dashboards, alerting, historical graphs, process actions, menu bar metrics, and sending metrics to LLM context are deferred.
