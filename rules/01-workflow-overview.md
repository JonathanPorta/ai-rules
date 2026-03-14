# Workflow Overview

Every feature follows this sequence. No steps are optional.

## Scope Check

Before starting, determine the scope of the work:

- **Multi-feature project** (new product, major initiative, multiple workstreams):
  Start with [00-project-planning.md](00-project-planning.md) to create a phased
  project plan BEFORE generating any PRDs.
- **Single feature** (one feature, bug fix, improvement): Proceed directly to
  Phase 1 below.

When in doubt, ask the human:

> "This looks like it could involve multiple features. Should we create a phased
> project plan, or treat this as a single feature?"

## Phases

### Phase 1: PRD (Human + AI)

1. Human provides a feature request, bug report, or improvement idea (any level of detail).
2. AI explores the codebase and produces a **Codebase Analysis** (see [02-prd.md](02-prd.md)).
3. **Human reviews the codebase analysis** for misunderstandings. &larr; GATE
4. AI asks clarifying questions with lettered options for quick response.
5. AI generates the PRD following [02-prd.md](02-prd.md).
6. **Human reviews and approves acceptance criteria.** &larr; GATE
7. PRD is saved to `tasks/prd-<feature-name>.md`.

> **Why the analysis gate exists:** If the AI misunderstands the codebase, every
> downstream artifact — PRD, tasks, implementation — will be wrong. Catching
> misunderstandings here costs seconds. Catching them in implementation costs hours.

> **Why the AC gate exists:** Acceptance criteria are the contract. Everything
> downstream — tasks, validation, implementation — flows from them. Getting them
> wrong here means building the wrong thing efficiently.

### Phase 2: Task Decomposition (AI generates, Human confirms)

1. AI generates parent tasks from the approved PRD.
2. **Human confirms parent tasks align with intent.** &larr; GATE
3. AI generates sub-tasks with validation criteria per [03-task-generation.md](03-task-generation.md).
4. AI identifies relevant files by READING THE CODEBASE (not guessing).
5. Task list is saved to `tasks/tasks-<feature-name>.md`.

> **Why this gate exists:** Catching a wrong decomposition here costs minutes.
> Catching it after three tasks are implemented costs hours.

### Phase 3: Validation-First Implementation (AI, per task)

For EACH task:

1. AI writes validation steps BEFORE implementation per [04-validation-first.md](04-validation-first.md).
2. AI presents validation steps to the human (unless human has opted into auto-proceed).
3. AI implements the task per [05-task-execution.md](05-task-execution.md).
4. AI executes validation steps and reports results.
5. On pass: check off task, update session state, proceed to next.
6. On fail: stop, report, wait for guidance.

**Session state:** The AI maintains a session state file throughout this phase
(see [06-session-state.md](06-session-state.md)). This file persists decisions,
codebase learnings, and current position so that context loss does not require
re-exploration. Updated after each parent task and after any human decision.

### Phase 4: Feature Verification (Human)

1. AI summarizes completed work against the original acceptance criteria.
2. AI presents an evidence table mapping each AC to proof of completion.
3. **Human verifies each acceptance criterion is met.** &larr; GATE
4. Unmet criteria become new tasks (return to Phase 2).

> **Why this gate exists:** The AI's job is to present evidence. The human's job
> is to decide whether that evidence is sufficient. Features are not done until
> the human says they are.

## Gate Summary

| Gate | Phase | Who Approves | What's Approved |
|------|-------|-------------|-----------------|
| 0 | Project Planning | Human | Phased plan and dependencies (multi-feature only) |
| 1 | PRD | Human | Codebase analysis accuracy |
| 2 | PRD | Human | Acceptance criteria |
| 3 | Task Decomposition | Human | Parent task breakdown |
| 4 | Feature Verification | Human | AC met with evidence |
| 5 | Phase Gate | Human | Phase exit criteria met (multi-feature only) |

**Optional gate:** Per-task validation plan review (Phase 3, step 2). The human
can opt into auto-proceed to skip this for trusted workflows.

## File Organization

All artifacts are stored in a `tasks/` directory at the project root.

### Single Feature

```
tasks/
  prd-<feature-name>.md
  tasks-<feature-name>.md
  session-state-<feature-name>.md
```

### Multi-Feature Project

```
tasks/
  project-plan.md
  phase-1/
    prd-<feature-a>.md
    tasks-<feature-a>.md
    session-state-<feature-a>.md
    prd-<feature-b>.md
    tasks-<feature-b>.md
    session-state-<feature-b>.md
  phase-2/
    prd-<feature-c>.md
    tasks-<feature-c>.md
    session-state-<feature-c>.md
```

Use kebab-case for feature names. If the feature request is "Add user profile editing",
the files are `prd-user-profile-editing.md` and `tasks-user-profile-editing.md`.
