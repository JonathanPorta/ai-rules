# Rule Loading Order

Use this loading order so AI agents read enough structure without getting lost.

## 1. Root contract

Read `AGENTS.md` first.

This answers:
- what rules are mandatory for all work
- what domain rules are required for design work
- what optional rules may be enabled
- what principles override local convenience

## 2. Core workflow rules

For implementation work, load:
- `rules/00-project-planning.md` when scope is multi-feature
- `rules/01-workflow-overview.md`
- `rules/02-prd.md`
- `rules/03-task-generation.md`
- `rules/04-validation-first.md`
- `rules/05-task-execution.md`
- `rules/06-session-state.md`
- `rules/07-command-surface.md`
- `rules/09-git-and-publication-boundaries.md`
- `rules/13-phase-gate-audits.md`

Optional rules listed under `Optional Rules → Enabled` in `AGENTS.md` are
loaded after the required set:

- `rules/08-tdd-enforcement.md` (when enabled)
- `rules/10-branch-pr-commit-conventions.md` (when enabled)
- `rules/11-styleguide-overlays.md` (when enabled)
- `rules/12-human-copyable-outputs.md` (enabled by default in this repo)

## 3. Domain rules when relevant

For design work, additionally load:
- `rules/design/30-design-principles.md`
- `rules/design/31-ux-brief-and-intent.md`
- `rules/design/32-information-architecture.md`
- `rules/design/33-user-journeys-and-state-inventory.md`
- `rules/design/34-trust-feedback-and-confirmation.md`
- `rules/design/35-visual-system-and-hierarchy.md`
- `rules/design/36-screen-review-and-critique.md`
- `rules/design/37-accessibility-and-legibility.md`
- `rules/design/38-design-memory-and-consistency.md`

## 4. Templates last

Use templates only after the relevant rules are loaded. Templates provide
structure; they do not replace judgment.

## 5. Preserve continuity

When work spans multiple sessions, use session state and explicit design
artifacts so the next session can resume without guessing.
