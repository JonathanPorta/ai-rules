# Task Execution Rules

## Sequence

Execute tasks in order. Do not skip ahead. Do not parallelize tasks unless they
are explicitly marked as independent and have no shared file modifications.

## Per-Task Checklist

For each task, follow this sequence:

1. Read the task description and its validation criteria.
2. Read the session state file (if resuming — see [06-session-state.md](06-session-state.md)).
3. Write the validation plan (per [04-validation-first.md](04-validation-first.md)).
4. Complete the task preflight ledger.
5. Present the validation plan unless session state explicitly records `Validation Review Mode: auto-proceed`.
6. Write failing tests (if applicable).
7. Implement the task.
8. Run all validation steps.
9. Report validation results in an inspectable artifact.
10. On any-fail: fix and re-validate. Do NOT mark complete.
11. On all-pass: update the session state file (current position, decisions, learnings).
12. Create the per-parent-task commit with a meaningful message referencing the task number.
13. Then mark the task `[x]` in the task file and proceed.

## Progress Tracking

### Real-time updates
Update the task markdown file as you complete each sub-task. Do not batch
checkbox updates. Mark each sub-task as you finish it.

### Stopping mid-feature
If you must stop before completing all tasks:

1. Update the session state file with a detailed "What's Next" section
   (see [06-session-state.md](06-session-state.md)).
2. Add a brief status block at the top of the task file:

```markdown
## Current Status
**Stopped after:** Task 2.3
**Reason:** [why you stopped]
**Session state:** session-state-<feature-name>.md has full context
```

### Resuming work
When picking up a feature after a break or context loss, read files in this
order:
1. `session-state-<feature>.md` — where you are, what you know
2. `tasks-<feature>.md` — what's done, what's left
3. `prd-<feature>.md` — acceptance criteria and codebase analysis
4. Only then start reading implementation files

### Task file is source of truth
The task markdown file is the canonical record of progress. The session state
file is the canonical record of context. Keep both accurate.

### Reconciliation audit cadence
After every two completed parent tasks, run a reconciliation audit comparing:
- implementation vs PRD,
- implementation vs task file,
- task file vs session state,
- and implementation vs any applicable design/spec documents.

This is in addition to the final reconciliation audit in the Completion section.

## Scope Discipline

### No silent additions
If you discover work that needs doing but is not in the task list, do NOT
silently do it. Add it as a new task and flag it to the human:

> "I discovered [X] needs to happen for [reason]. I have added it as task N.0.
> Should I proceed with it, or should we discuss first?"

### Scope drift notice required
If implementation requires a new externally visible command, route, schema change,
dependency, parent task, or any new file/component that materially changes scope,
review surface, or acceptance-criteria coverage beyond what was approved in the
PRD or task list, stop and surface it to the human before proceeding.

Use this format:

> "Scope drift notice:
> - Discovered change: [what changed]
> - Why it is needed: [reason]
> - Affected acceptance criteria: [ACs or none]
> - Options:
>   A) Approve and proceed
>   B) Add/adjust tasks first
>   C) Revisit the PRD"

Minor refactors that do not change scope may proceed, but they should still be
noted in the task file or session state when they materially affect review.

### No silent removals
If a task turns out to be unnecessary, do not delete it. Mark it as skipped
with a reason:

```markdown
- [~] 3.0 Add database migration            <- SKIPPED
  - **Reason:** Schema already supports the new fields (verified in
    `src/db/schema.ts:45`). No migration needed.
```

### No criteria changes
Never modify acceptance criteria without human approval. If you believe an AC
is wrong, incomplete, or impossible, raise it:

> "AC-2 specifies a 50ms response time, but the current architecture requires
> two sequential database queries that average 80ms combined. Options:
> A) Optimize with a single joined query
> B) Add caching
> C) Revise the AC to 150ms
> Which approach do you prefer?"

## Error Handling

### Fix and re-validate
When a validation step fails:
1. Diagnose the root cause.
2. Fix the issue.
3. Re-run ALL validation steps for that task (not just the one that failed).
4. Report the complete results table.

### Three-strike escalation
If a task fails validation three times:
1. Stop. Do not attempt a fourth fix.
2. Report to the human:
   - What you tried in each attempt
   - The error output from each attempt
   - Your best theory on the root cause
   - 2-3 suggested next steps
3. Wait for guidance before continuing.

### Regression checking
After completing each task, run the project's existing test suite (if one
exists) to catch regressions:

```
[project test command]
```

If new test failures appear that were not present before your changes, fix them
before proceeding. These count as validation failures for the current task.

## Code Quality

### Read before write
Before modifying any file, read it first. Understand the existing patterns,
naming conventions, and structure. Match them.

### Follow existing patterns
Do not introduce new architectural patterns, libraries, or conventions unless
the task explicitly calls for it. When in doubt, match what is already there.

### No test infrastructure? Flag it.
If the project has no test runner, linter, or type checker, flag it before
starting implementation:

> "No test infrastructure exists in this project. Should I set one up as
> task 0.0, or should we proceed with manual validation only?"

## Completion

When all tasks are checked off:

### 1. Run full project checks
Execute the project's complete validation suite using the repository's canonical
command surface when it exists (see [07-command-surface.md](07-command-surface.md)):
- Full test suite
- Linter
- Type checker (if applicable)
- Build (if applicable)

### 2. Present the acceptance criteria verification table

```markdown
## Acceptance Criteria Verification

| AC   | Criterion                            | Evidence                              | Status |
|------|--------------------------------------|---------------------------------------|--------|
| AC-1 | Users can edit their profile         | Tests pass, manual verification done  | MET    |
| AC-2 | Invalid input returns 422            | 4 test cases covering edge cases      | MET    |
| AC-3 | Changes persist across page reloads  | Integration test confirms DB write    | MET    |
```

### 3. Run a reconciliation audit

Before declaring the feature complete, compare:
- implementation vs PRD,
- implementation vs task file,
- task file vs session state,
- and implementation vs any applicable design/spec documents.

Classify findings as:
- **blocker** — must be fixed before sign-off,
- **major** — must be surfaced and resolved before sign-off,
- **minor** — can be logged as follow-up work,
- **info** — no action required.

### 4. List any discovered issues or follow-up work

```markdown
## Follow-Up Items
- [ ] Performance: Profile page loads in 400ms, could be optimized with caching
- [ ] Tech debt: `src/api/users.ts` is now 350 lines, consider splitting
- [ ] Enhancement: Bulk profile updates not supported (was a non-goal)
```

### 5. Wait for human sign-off
Features are not complete until the human confirms. Present the evidence and
wait:

A parent task should not be treated as complete until:
- the validation results table exists,
- evidence bullets or notes exist for the implemented checks,
- the session state has been updated,
- and the corresponding commit has been created.

> "All tasks are complete and validated. The acceptance criteria verification
> table is above. Please review and confirm, or identify any criteria that
> need additional work."

## Commit Conventions

Create one commit per completed parent task (not each sub-task). The commit is
part of completing the parent task, not a follow-up step after completion.
Reference the task number in the commit message:

```
feat: implement profile update API (task 2.0)
```

Follow the project's existing commit conventions if they exist. If none exist,
use conventional commits (feat, fix, chore, refactor, test, docs).
