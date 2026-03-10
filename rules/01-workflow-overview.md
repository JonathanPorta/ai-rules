# Workflow Overview

Every feature follows this sequence. No steps are optional.

## Phases

### Phase 1: PRD (Human + AI)

1. Human provides a feature request, bug report, or improvement idea (any level of detail).
2. AI generates a PRD following [02-prd.md](02-prd.md).
3. AI presents clarifying questions with lettered options for quick response.
4. **Human reviews and approves acceptance criteria.** &larr; GATE
5. PRD is saved to `tasks/prd-<feature-name>.md`.

> **Why this gate exists:** Acceptance criteria are the contract. Everything
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
5. On pass: check off task, proceed to next.
6. On fail: stop, report, wait for guidance.

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
| 1 | PRD | Human | Acceptance criteria |
| 2 | Task Decomposition | Human | Parent task breakdown |
| 3 | Feature Verification | Human | AC met with evidence |

**Optional gate:** Per-task validation plan review (Phase 3, step 2). The human
can opt into auto-proceed to skip this for trusted workflows.

## File Organization

All artifacts are stored in a `tasks/` directory at the project root:

```
tasks/
  prd-<feature-name>.md
  tasks-<feature-name>.md
```

Use kebab-case for feature names. If the feature request is "Add user profile editing",
the files are `prd-user-profile-editing.md` and `tasks-user-profile-editing.md`.
