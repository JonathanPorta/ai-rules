# ai-rules

Structured rules for AI-assisted development. Forces codebase understanding,
acceptance criteria, validation-before-implementation, and human gates at
critical decision points.

## The Problem

AI coding agents will happily generate code without understanding the codebase,
skip validation, and mark their own work complete. This leads to features that
compile but don't work, tasks that are checked off but not verified, and scope
that silently drifts.

## The Solution

A set of mandatory rules that enforce:

1. **Codebase analysis before proposals** — AI must document its understanding and get human confirmation
2. **Human-approved acceptance criteria** before any code is written
3. **AI-generated validation steps** before each task is implemented
4. **Observable proof** of task completion (not self-assessment)
5. **Human gates** at critical decision points
6. **Phased project planning** for multi-feature initiatives
7. **Session state persistence** so context loss doesn't mean knowledge loss

## Install

### One-liner (recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/JonathanPorta/ai-rules/main/install.sh | bash
```

This will:
- **Fresh install:** `git subtree add` the latest release to `.ai-rules/`
- **Update:** `git subtree pull` to the latest release if already installed
- **Abort:** warn and exit if `.ai-rules/` exists but wasn't installed by this script

### Manual: Git Subtree

```bash
# Add as a subtree (pin to a release tag)
git subtree add --prefix=.ai-rules https://github.com/JonathanPorta/ai-rules.git v1.0.0 --squash

# Update later
git subtree pull --prefix=.ai-rules https://github.com/JonathanPorta/ai-rules.git v1.2.0 --squash
```

### Manual: Git Submodule

```bash
git submodule add https://github.com/JonathanPorta/ai-rules.git .ai-rules
```

### Manual: Just copy it

```bash
cp -r ai-rules/ /path/to/your/project/.ai-rules/
```

## Platform Setup

After installing, generate platform-specific config stubs:

```bash
# Wire up for specific platforms
.ai-rules/setup.sh --platforms cursor,windsurf,copilot

# Wire up for all supported platforms
.ai-rules/setup.sh --platforms all

# See what's supported
.ai-rules/setup.sh --list
```

The setup script creates thin stub files at each platform's expected config
location (e.g., `.cursorrules`, `.windsurfrules`). These stubs reference
`.ai-rules/AGENTS.md` and leave room for project-specific additions.

### Platform Details

| Platform | Config Location | Auto-discovers? |
|----------|----------------|-----------------|
| Claude Code | `.ai-rules/AGENTS.md` | Yes — no stub needed |
| Cursor | `.cursorrules` | No — stub created by setup.sh |
| Windsurf | `.windsurfrules` | No — stub created by setup.sh |
| GitHub Copilot | `.github/copilot-instructions.md` | No — stub created by setup.sh |
| Amp | `.amp/rules/ai-rules.md` | No — stub created by setup.sh |

## Custom Agents (GitHub Copilot)

The `agents/` directory contains pre-built agent definitions for use with
[GitHub Copilot coding agent](https://docs.github.com/en/copilot/reference/custom-agents-configuration).
When you run `setup.sh --platforms copilot`, these agents are copied to
`.github/agents/` in your project.

| Agent | Tools | Purpose |
|-------|-------|---------|
| [planner](agents/planner.md) | read, search | Explores the codebase, produces analysis, and generates PRDs with acceptance criteria. Does not write code. |
| [implementer](agents/implementer.md) | read, search, edit, execute | Decomposes approved PRDs into tasks and implements them using validation-first development. |
| [validator](agents/validator.md) | read, search, edit, execute | Writes validation plans and test cases before implementation, then executes them to verify task completion. |
| [reviewer](agents/reviewer.md) | read, search, execute | Reviews completed work against acceptance criteria and produces verification evidence tables. |

These agents divide the ai-rules workflow into distinct roles with appropriate
tool access:

- **planner** handles Phases 1–2 (PRD and task generation). Limited to read-only
  tools to enforce human gates before any code is written.
- **validator** handles the validation-first discipline from Phase 3. Writes
  validation plans, creates failing tests (red phase), and runs all validation
  checks after implementation (green phase). Can write test files but not
  implementation code.
- **implementer** handles Phase 3 implementation. Takes the validator's failing
  tests and validation plan as a contract, then writes the code to make them pass.
- **reviewer** handles Phase 4 (feature verification). Has execute access to
  run tests independently but cannot modify code — enforcing separation between
  implementation and review.

## Structure

```
.ai-rules/
  .version                         # Origin and version tracking
  AGENTS.md                        # Entry point and core principles
  setup.sh                         # Platform stub generator
  install.sh                       # curl|bash installer
  rules/
    00-project-planning.md         # Phased planning for multi-feature projects
    01-workflow-overview.md         # End-to-end process with human gates
    02-prd.md                      # Codebase analysis, PRD generation, acceptance criteria
    03-task-generation.md          # Task decomposition with validation criteria
    04-validation-first.md         # Write validation before implementation
    05-task-execution.md           # Execute tasks, track progress, verify completion
    06-session-state.md            # Persist context across sessions
    07-tdd-enforcement.md          # (Optional) Red-then-green TDD evidence
  agents/
    planner.md                     # PRD and project planning agent
    validator.md                   # Validation plan and test-first agent
    implementer.md                 # Validation-first task implementation agent
    reviewer.md                    # Feature verification and AC review agent
  scripts/
    tdd-check.sh                   # (Optional) Git timestamp TDD verifier
  templates/
    project-plan.md                # Blank project plan template
    prd.md                         # Blank PRD template
    tasks.md                       # Blank task list template
    session-state.md               # Blank session state template
```

## How It Works

### Single Feature Workflow

```
Feature Request
  → Codebase Analysis (AI writes, human reviews)     ← GATE
  → PRD with Acceptance Criteria (human approves)     ← GATE
  → Task Decomposition (human confirms parent tasks)  ← GATE
  → For each task:
      → Validation plan (AI writes before coding)
      → Implementation
      → Validation execution (pass/fail reported)
  → Feature Verification (human confirms ACs met)     ← GATE
```

### Multi-Feature Project Workflow

```
Project Vision
  → Project Brief (human approves)                    ← GATE
  → Phased Plan with Dependencies (human approves)    ← GATE
  → For each phase:
      → PRDs for each feature (single feature workflow above)
      → Phase Gate Review (human confirms exit criteria)  ← GATE
  → Project Completion Summary
```

## The Three Types of Criteria

| | Acceptance Criteria | Validation Criteria | Exit Criteria |
|---|---|---|---|
| **Owner** | Human | AI | Human + AI |
| **Scope** | Feature-level | Task-level | Phase-level |
| **When defined** | PRD phase | Pre-implementation | Project planning |
| **What it answers** | "What does done mean?" | "How do we prove this task got us there?" | "What must be true to move to the next phase?" |
| **Approval** | Required before any work | Human reviews if desired | Required before next phase |
| **Mutability** | Only with human approval | AI refines as needed | Only with human approval |

## Optional Rules

Some rules are opt-in. They live in the repo but are disabled by default.
To enable an optional rule, edit `AGENTS.md` and move it from the "Available"
list to the "Enabled" list under the Optional Rules section.

| Rule | What It Does | Enable When |
|------|-------------|-------------|
| [TDD Enforcement](rules/07-tdd-enforcement.md) | Requires red-then-green test evidence | Your team practices TDD and has test infrastructure |

Optional rules also come with supporting tooling in `scripts/`:
- `tdd-check.sh` — compares git timestamps to verify test-before-implementation ordering

## Extending for Your Organization

These rules are intentionally generic. Fork this repo to add:

- Organization-specific coding standards
- CI/CD pipeline validation steps
- Project management tool integration (Jira, Linear, etc.)
- Security and compliance checks
- Infrastructure-specific validation patterns

Keep extensions in a separate file (e.g., `rules/06-org-standards.md`) and
reference it from your fork's `AGENTS.md`.

## Versioning

Releases are cut automatically on merge to `main`:
- `BREAKING` or `major:` in commit message → major bump
- `feat:` or `minor:` → minor bump
- Everything else → patch bump

The `.version` file tracks the installed version and origin, used by the
installer to detect updates.

## License

Apache-2.0
