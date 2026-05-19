# gridOS — vision

> A native macOS app for Apple Silicon that reimagines eDEX-UI as a real Mac-first tool, not an Electron homage to Tron.

This document captures the design intent. It is opinionated about *what* gridOS is and is not, lighter on *how* to build it. Implementation choices are deliberately left for the development team to make on the Mac.

---

## Why gridOS exists

eDEX-UI (2017–2021) nailed the sci-fi terminal aesthetic but is now archived, Electron-based, and feels like a 2019 fan project rather than a 2026 tool. It uses ~500MB of RAM, takes seconds to launch, and runs at the mercy of Chromium's renderer.

gridOS aims to be the same vibe, executed as a serious native macOS app. Better performance by an order of magnitude. Better aesthetics. Real macOS integration. Features that earn its existence as more than a screensaver-with-a-shell.

## Non-goals

- **Not cross-platform.** Mac-first, Mac-only. Apple Silicon, current macOS. No Electron, no Tauri, no compromise abstraction layer.
- **Not a fork of eDEX-UI.** From-scratch implementation. We owe credit for the inspiration, not the code.
- **Not a screensaver.** A real terminal you'd choose over iTerm2 / Ghostty / Terminal.app for actual work — at least for some flows.
- **Not configurable to the point of paralysis.** Opinionated defaults. Themes and modes, not a thousand toggles.

## Performance targets

These are the numbers to beat. If we hit them, the rewrite was justified.

| Metric | eDEX-UI | gridOS target |
|---|---|---|
| Resident RAM | 500MB–1GB | < 100MB |
| Cold start | 3–5s | < 500ms |
| Animation FPS | 30–60 (inconsistent) | 120 sustained on ProMotion |
| Idle CPU | 2–5% | < 0.5% |
| Binary size | 150MB+ | < 50MB |
| Terminal input latency | 30–80ms | < 5ms (Ghostty-class) |

## Pillar 1 — Metal as the visual identity

Every visible element rendered via Metal shaders, not SwiftUI's compositor. This is where "way cooler than the original" lives. The shader layer is what distinguishes gridOS from "Tron-themed iTerm."

Concrete shader work:
- Procedural backgrounds (animated, GPU-only, no asset files)
- Panel decorations and borders rendered as SDF / procedural geometry
- Particle effects responsive to terminal activity (keystrokes, output bursts)
- Optional CRT post-processing: scanlines, bloom, signal noise, RGB shift, chromatic aberration
- Smooth, GPU-accelerated terminal text rendering (no SwiftUI Text views — direct glyph rasterization to a Metal texture atlas)

## Pillar 2 — Procedural per-machine visual signature

**This is the killer differentiator.** Every gridOS install has a unique aesthetic mathematically derived from a stable machine identifier (likely a hash of hardware UUID + first-launch timestamp). No two users see exactly the same thing.

What varies per install:
- Background generative noise field (seeded animation pattern)
- Accent color palette (deterministic from seed within the active aesthetic mode)
- Particle behavior curves
- Panel decoration micro-details
- Boot-up "handshake" animation that's specific to your machine

This makes gridOS feel like *your* gridOS, not a copy of someone else's setup. Screenshots become identifying. Demos become personal. It's a small idea with disproportionate emotional payoff.

## Pillar 3 — Aesthetic modes

One codebase, multiple visual identities. Hotkey to switch (default: `⌘⇧M`).

- **Tron** — Original homage. Blue/cyan, grid lines, light cycles.
- **Severance** — Austere monochrome. Single dim accent. Minimum motion. Corporate dystopia.
- **Cyberpunk** — Blade Runner 2049 palette. Magenta + amber + deep teal. Volumetric haze.
- **Matrix** — Green falling glyphs. Glitch transitions. Heavy CRT post-processing.
- **Apple-native** — Sits in macOS like a first-party tool. SF Symbols. Standard window chrome. Light/dark adaptive. The "I want to use this for work" mode.

Modes are not just color swaps — each is a coherent design system (motion, shapes, shaders, sounds).

## Pillar 4 — macOS integration

gridOS should feel like Apple built it. Things competitors fake or skip:

- **Menu bar widget** — terminal preview, system stats, recent commands accessible from anywhere
- **Notification Center widget** — live system stats
- **Quick Look integration** — preview terminal session files
- **Spotlight integration** — search commands and sessions
- **Stage Manager support** — first-class window grouping
- **Touch Bar** support (for the holdouts still on Intel)
- **Keychain** for secrets/SSH keys
- **Codesigning + notarization** from day one
- **Universal Control / Continuity** awareness where applicable

## Pillar 5 — LLM-integrated terminal

The terminal isn't just a shell wrapper — it has Claude built in.

- **Command palette** (`⌘K`): natural language → suggested commands, with explanation
- **Inline explain**: select output, ask "what does this mean?"
- **Error-to-fix**: when a command fails, surface a one-tap "ask Claude to fix" option
- **Conversational shell mode**: optional REPL where you describe intent and Claude executes (with confirmation gating for destructive ops)
- **Local context**: Claude sees cwd, recent commands, git state when answering

API key stored in Keychain. Privacy-first — no telemetry, all context stays local until explicitly sent.

## Pillar 6 — System stats that mean something

eDEX-UI's panels were beautiful but lied — most numbers were random animations. gridOS's panels are real data, rendered beautifully:

- **CPU flame graphs** — per-core utilization, top consumers, sampling-based stack visualization
- **GPU utilization** — per-app GPU time, Metal command queue depth
- **Network topology** — live connections visualized as a node graph, geo-located if external
- **Disk I/O** — read/write hotspots, per-process breakdown
- **Memory pressure** — actual swap/compression state, not just "X GB used"
- **Thermals + power** — fan speed, package temps, power draw

These should be informative enough that gridOS replaces a casual glance at Activity Monitor.

## Pillar 7 — Multi-pane terminal + plugins

- Native split-pane via gesture or hotkey (no tmux required)
- Drag panes between windows
- Plugin API from day 1 — third parties can add panels, themes, command palette providers
- Plugin language: probably Swift via dynamic library loading, or a sandboxed JS surface for safer distribution. TBD.

## Out-of-scope (for v1)

To stay honest about scope:

- Cross-platform (already excluded — non-goal)
- iPad / iOS companion (interesting v2 idea, not v1)
- Apple Watch companion (joke until proven otherwise)
- Voice control (defer)
- Cloud sync of sessions (defer; local-first is the v1 stance)
- Built-in SSH client improvements (delegate to existing tools)

## Suggested phases

A rough sequencing that keeps each phase shippable / demoable:

**Phase 1 — Foundation (the "afternoon" version)**
- Xcode project, SwiftUI shell, embedded terminal via SwiftTerm
- Single Metal-rendered background (one shader, one mode)
- Window chrome, basic keybinds
- *Demoable as*: a working terminal with a Tron background

**Phase 2 — The look**
- Three aesthetic modes implemented
- Real panel layouts (three panels: top stats, left commands, right activity)
- Per-machine procedural seed system wired up
- *Demoable as*: "this is the eDEX-UI replacement"

**Phase 3 — The substance**
- Real system stats (CPU, GPU, memory, network)
- LLM command palette (basic Claude integration)
- Multi-pane terminal
- *Demoable as*: "I actually use this daily"

**Phase 4 — Polish + ship**
- Remaining aesthetic modes
- Plugin API
- Notarization, distribution (DMG, possibly Mac App Store, possibly Homebrew cask)
- Marketing site
- *Demoable as*: 1.0

## Success criteria

gridOS 1.0 is successful if:
1. A reasonable developer would replace iTerm2/Ghostty with it for at least some workflows
2. The performance numbers above are met
3. Three independent screenshots of gridOS are visibly different (procedural signature works)
4. Hacker News reaction is "this is genuinely impressive" rather than "yet another Tron clone"
