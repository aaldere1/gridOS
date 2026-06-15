# gridOS Product Desirability

Status: version 1.0.5 product pass
Last updated: 2026-06-15

App Store readiness remains secondary to product quality. The current bar is
not compliance. The current bar is whether a serious Mac terminal user would
feel the app is worth opening again tomorrow.

## Honest Product Read

gridOS is now credible as a direct-download version. It has a working
native terminal, memorable per-machine visual identity, multi-pane state,
calmer live metrics, and a Command-K flow that reads like a guarded runbook
rather than a generic AI form. The product is still early, but it no longer
feels like pre-release paperwork wrapped around a terminal.

Version 1.0.5 keeps the 1.0.4 production base and sharpens the user-facing
value by making first-use AI setup explicit, updating Anthropic and OpenAI model
defaults, adding project-folder entry, protecting live shell sessions from
accidental close/quit, replacing fake examples with realistic terminal snippets,
clipping restored multi-pane terminal surfaces cleanly, explaining Command-K
helper modes in product, opening Settings as a resizable macOS window, and
deriving the visible app version from signed bundle metadata.

## What Must Become Obvious

| Product question | Current answer | Required direction |
| --- | --- | --- |
| Does it look unique in one screenshot? | Yes | Keep the visual signature prominent without letting the shell feel secondary. |
| Does first launch feel premium? | Yes | Keep first launch as a local launch briefing, not compliance copy. |
| Would a developer replace another terminal? | Plausible | Keep proving shell reliability and update/install behavior on clean machines. |
| Does AI Command Helper feel like a reason to use it? | Yes | Keep expanding high-signal result states and provider setup ergonomics. |
| Does the UI have class? | Yes | Preserve quiet density, restraint, and local-first confidence. |

## Current Product Moves

- Surface a stable local visual signature derived from the procedural visual seed.
- Show the signature in the first-run launch briefing and the right rail.
- Keep the signature display-only; it does not reveal the install seed.
- Keep terminal workspace area dominant.
- Make the right rail feel like a local system signal, not a generic process list.
- Make Command-K read as a guarded intelligence briefing and result runbook, not a plain provider form.
- Make the direct installer feel native and obvious: open DMG, drag gridOS into Applications, launch.
- Make project entry obvious through Open Folder instead of expecting users to infer workspace behavior.
- Confirm before closing live shell processes, including window close and app quit.
- Keep App Store sandbox work staged but inactive while the direct version is being distributed.
- Keep live metrics on a calmer cadence so the app idles quietly.
- Use physical footprint, idle CPU, dispatch latency, heavy-output, and frame-pacing evidence as the release performance gate.

## Next Product Moves

1. Keep the 1.0.5 GitHub release assets and download-facing notes aligned with `docs/production-direct-release.md`.
2. Keep the public repository posture source-available proprietary unless a separate open-source licensing decision is made.
3. Run clean-Mac Finder/Gatekeeper UAT as final external validation when a separate Mac is available.
4. Collect first-user feedback on whether AI Command Helper feels useful enough to become a daily workflow, not just a novelty.
