# Command Surface and Makefile Standards

## Purpose

To keep local development, AI execution, documentation, and CI aligned, projects
should expose common workflows through a consistent command surface.

When a project reasonably supports GNU Make, that command surface MUST be a
`Makefile`.

This prevents drift where:
- developers run one set of commands locally,
- CI runs a different set of commands,
- documentation describes a third set,
- and AI agents invoke raw tool commands directly instead of the project's
  canonical workflow.

## Rule

If the project environment reasonably supports `make`, the repository MUST
provide a `Makefile` as the canonical command surface for common development,
validation, build, and release workflows.

When an appropriate Make target exists, AI agents MUST use the Make target
instead of invoking the underlying tool directly.

CI workflows MUST call Make targets for equivalent operations when those targets
exist.

## What "Reasonably Supports Make" Means

A project reasonably supports `make` when:
- the repository is primarily developed in Unix-like environments (Linux, macOS,
  WSL, containers, CI runners), or
- the build/test/dev workflows can be cleanly wrapped by Make targets, or
- the repository already uses shell-based or CLI-driven workflows that fit a
  Makefile naturally.

A Makefile is NOT required when:
- the project is truly platform-specific and `make` would be unnatural or
  fragile,
- the repository already has a more appropriate canonical task runner and the
  human explicitly prefers it,
- or the human explicitly directs otherwise.

If a Makefile is not used, the reason MUST be documented in the codebase
analysis or PRD.

## Canonical Command Surface

The Makefile is the public interface for common project operations.

This means:
- local developer instructions should prefer `make` targets,
- AI agents should prefer `make` targets,
- CI should prefer `make` targets,
- helper scripts may exist, but Make should orchestrate them when applicable.

### Good
- README says `make test`
- CI runs `make test`
- AI runs `make test`

### Bad
- README says `pytest`
- CI runs `poetry run pytest`
- AI runs `pytest`
- a `make test` target exists but is ignored

## Required Behavior

### 1. Discover the canonical command surface before use

Before running project workflow commands, inspect the repository's canonical
command surface and identify the public commands or targets relevant to the
work. If the repository uses a `Makefile`, inspect the `Makefile`; otherwise,
inspect the appropriate task runner, script entry points, or documented workflow
interface. Do not assume raw commands first and only discover the canonical
commands or Make targets later.

### 2. Prefer existing Make targets

If a relevant Make target exists, use it.

Examples:
- use `make test` instead of `pytest`, `cargo test`, or `npm test`
- use `make lint` instead of calling the linter directly
- use `make build` instead of invoking the build tool directly
- use `make dev` instead of manually reconstructing the development command

Only bypass a Make target when:
- the target does not cover the needed operation,
- the target is broken and fixing it is part of the work,
- or the human explicitly directs otherwise.

If bypassing a target, state why.

### 3. Create or extend the Makefile when appropriate

If the repository reasonably supports Make but has no Makefile, create one when:
- introducing or standardizing developer workflows,
- adding CI validation that should also be runnable locally,
- or the human requests workflow normalization.

If a Makefile exists, extend it instead of creating duplicate shell scripts or
duplicating raw commands in CI.

### 4. Standard target vocabulary

Use these standard target names when they apply:

#### Core targets
- `help` — list available commands
- `setup` or `install` — first-time setup / dependency installation
- `dev` — start local development mode
- `build` — produce build artifacts
- `test` — run the primary automated test suite
- `lint` — run linting
- `format` — apply formatting
- `check` — fast validation without full build where applicable
- `clean` — remove generated artifacts

#### Common optional targets
- `e2e` — end-to-end tests
- `package` — package artifacts
- `docs` — generate documentation
- `update` — update dependencies or generated assets
- `release` — perform release workflow
- `plan` — planning/dry-run workflow (common in infra repos)
- `deploy` — deployment workflow

Use the conventional name unless there is a strong project-specific reason not
to.

### 5. Help target required

The Makefile SHOULD include a `help` target or equivalent self-documenting
mechanism so humans and AI agents can discover the available workflow.

A good `help` target:
- lists common targets,
- provides a one-line description for each,
- exposes the intended public command surface.

### 6. Keep business logic centralized

Do not duplicate the same workflow logic across:
- CI YAML,
- README examples,
- AI instructions,
- shell scripts,
- and Make targets.

Prefer:
- Makefile as orchestration layer,
- scripts for reusable internals when needed,
- CI calling the Makefile,
- docs referencing the Makefile.

### 7. Keep target intent stable

Once a standard target exists, do not silently change its meaning in a way that
will surprise developers, CI, or AI agents.

For example:
- `make test` should remain the primary automated test command
- `make lint` should remain the primary lint command
- `make build` should remain the primary build command

If behavior must change significantly, document it clearly.

## Makefile Quality Standards

When creating or modifying a Makefile:

### Include `.PHONY` where appropriate
Declare phony targets explicitly.

### Keep names predictable
Prefer short, conventional names over clever names.

### Keep targets composable
Let targets call other targets where helpful.

### Keep output readable
Commands should be understandable from logs in local runs and CI.

### Avoid unnecessary duplication
If multiple targets share logic, factor it cleanly.

### Preserve project-specific detail
The exact implementation may vary by stack. The standard governs the command
surface, not the internal tool choice.

## CI Requirements

When CI performs an operation that has a corresponding Make target, CI MUST call
the Make target instead of duplicating the raw underlying command.

Examples:
- test job uses `make test`
- lint job uses `make lint`
- build job uses `make build`
- validation job uses `make check`

This ensures local and CI workflows stay aligned.

If CI cannot use the Make target, document the reason in the workflow or PR.

## AI Agent Requirements

AI agents MUST treat the repository's canonical command surface as the first
place to look for project workflows. When a `Makefile` exists and is canonical,
it is the first place to look.

When analyzing a repository, identify:
- whether a Makefile exists,
- what public targets it exposes,
- whether CI uses them,
- whether README/docs use them,
- and whether command drift exists.

Before the first implementation step for a feature, the AI agent MUST record the
command-surface discovery in the codebase analysis, PRD, task file, or session
state. At minimum, identify:
- whether a Makefile exists,
- which public targets map to test, lint, build, dev, and check workflows,
- and whether any required workflow lacks a target.

When executing work:
- prefer Make targets for setup, validation, testing, linting, formatting,
  building, packaging, and release operations,
- update the Makefile when adding a new standard workflow,
- and avoid introducing direct raw commands into docs or CI when a Make target
  should exist.

## Validation

A repository satisfies this rule when all of the following are true:

1. A Makefile exists if the project reasonably supports Make.
2. The Makefile exposes the applicable common workflows.
3. Local docs prefer the Make targets.
4. CI uses the same Make targets for equivalent operations when they exist.
5. AI execution uses the Make targets instead of bypassing them unnecessarily.

## Examples

### Good pattern
- `make dev`
- `make test`
- `make lint`
- `make build`
- CI invokes those same targets
- README documents those same targets

### Bad pattern
- CI runs raw commands that differ from local workflows
- README documents commands not exposed by the Makefile
- AI calls raw tooling directly despite existing Make targets
- build/test/lint behavior is duplicated in several places and drifts over time
