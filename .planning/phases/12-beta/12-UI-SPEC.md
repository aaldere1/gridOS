# Phase 12: Beta - UI Spec

## Scope

Phase 12 UI work is limited to trust and support surfaces that a Beta tester needs before using the terminal:

- First-run privacy disclosure.
- Settings-accessible privacy/support surface.
- Support/feedback command or link surface.
- Diagnostic export copy that stays local and user-reviewed.

No marketing landing page is built inside the app. No telemetry opt-in, crash-upload prompt, or automatic diagnostics upload is added in this phase.

## UX Principles

- Dark only, native macOS, quiet and utilitarian.
- Terminal remains the primary surface; first-run UI must not feel like a sales page.
- Avoid blocking expert users longer than necessary, but make privacy defaults explicit for external testers.
- Prefer concise labels and concrete states over explanatory walls of text.
- Do not use decorative cards inside cards. Use normal macOS settings sections, icon buttons where appropriate, and stable dimensions.

## First-Run Privacy Disclosure

### Trigger

Show once for Beta builds unless the stored preference says the Beta privacy disclosure was accepted.

### Required Copy Points

The disclosure must contain exact or equivalent product facts:

- `Terminal sessions stay local to this Mac.`
- `Command Intelligence is opt-in and sends context only after preview approval.`
- `API keys are stored in Keychain.`
- `Risky commands are inserted for review instead of run automatically.`
- `Notifications and workspace indexing are off until you enable them.`
- `Diagnostics are local, sanitized, and user-reviewed.`

### Controls

- Primary action: `Continue`.
- Secondary action: `Open Privacy Settings`.
- No "upload diagnostics" action.

## Settings Privacy And Support Surface

Add or extend a Settings section with:

- Privacy disclosure status.
- Button to review the Beta privacy disclosure.
- Support contact placeholder from docs, such as `support@example.com` until the final address is chosen.
- Link or button to open the Beta feedback template in the repo/docs context when running locally.

## Feedback Copy Requirements

Use product-level language:

- Ask testers to include app version/build, macOS version, hardware class, and sanitized steps.
- Tell testers not to include shell history, terminal transcripts, environment variables, API keys, prompts, generated commands, provider responses, screenshots with secrets, or private file paths.
- Make no claim that diagnostics are automatically collected.

## Accessibility

- Disclosure must be reachable by keyboard.
- Buttons must have stable labels.
- VoiceOver should read the title and each privacy fact in order.
- Text must fit on narrow macOS windows without clipping.
- Respect the existing reduced-motion preference and system reduced-motion setting.

## Verification

- Source contains `BetaPrivacy`.
- Tests cover the default not-accepted state and persistence after acceptance.
- Source/docs contain the exact facts listed above.
- Full `xcodebuild ... CODE_SIGNING_ALLOWED=NO test` passes.
