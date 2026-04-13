# Session State Persistence

## Purpose

AI agents lose their working context when sessions end, context windows compact,
or conversations switch. The session state file preserves what the agent learned,
decided, and planned so that a new session can resume without re-exploring the
codebase or re-making decisions.

## The Session State File

For each active feature, maintain a session state file alongside the task file:

```
tasks/
  tasks-user-profile.md
  session-state-user-profile.md     <- session state
```

For multi-feature projects:

```
tasks/
  phase-1/
    tasks-auth-overhaul.md
    session-state-auth-overhaul.md
```

The filename follows the pattern `session-state-<feature-name>.md`.

## What It Contains

```markdown
## Session State: <feature-name>
Last updated: <ISO 8601 timestamp>

### Current Position
- **Current Phase:** Phase 1 / 2 / 3 / 4
- **Validation Review Mode:** required / auto-proceed
- **Working on:** Task X.Y — <task description>
- **Status:** <specific state, e.g., "test written and failing, implementation not started">
- **Blocked:** Yes/No — <reason if blocked>

### Key Decisions
Decisions made by the human during this feature's development. These are final
unless the human changes them.

- <Decision 1> — confirmed by human on <date or "this session">
- <Decision 2> — confirmed by human on <date or "this session">

### Codebase Understanding
What the agent learned about the codebase beyond the initial PRD analysis.
Include specific file paths and line references.

- `path/to/file.ts:42` — <what you learned>
- `path/to/other.ts` — <pattern or constraint discovered during implementation>

### What's Next
Ordered list of what to do when resuming.

1. <Next immediate action>
2. <Action after that>
3. <Upcoming task>

### Blockers / Open Questions
Anything unresolved that the human needs to weigh in on.

- <Question or blocker>
```

## When to Write

Update the session state file at these points:

### After each parent task completion
When you mark a parent task (e.g., `2.0`) as complete, update the session state
with the new current position, any decisions made during that task, and anything
learned about the codebase.

### After any human decision
When the human makes a judgment call (approves an approach, picks between options,
changes direction), record it in the Key Decisions section immediately. These are
the most expensive things to lose — re-asking wastes the human's time and may
get a different answer.

If the human opts into or out of validation auto-proceed, update the
`Validation Review Mode` field immediately.

### Before ending a session
If you know the session is ending (human says "stopping for today", context is
getting large, etc.), write a final update with detailed "What's Next" steps.

### When context is getting large
If you sense that context compaction may happen soon (many files read, long
conversation), proactively write the session state as insurance.

## When to Read

### First action on resume
When starting a new session on an existing feature, read the session state file
BEFORE reading any code. This tells you:
- Where you are in the task list
- What decisions have been made (don't re-ask)
- What you already know about the codebase (don't re-explore)
- What to do next

### Recovery order
When resuming work, read files in this order:
1. `session-state-<feature>.md` — where you are, what you know
2. `tasks-<feature>.md` — what's done, what's left
3. `prd-<feature>.md` — the acceptance criteria and codebase analysis
4. Only THEN start reading implementation files

## Rules

### Keep it concise
This is a working document, not a journal. One line per decision, one line per
learning. The goal is fast recovery, not comprehensive documentation.

### Decisions are immutable
Once a decision is recorded as "confirmed by human," do not change or remove it.
If a new decision contradicts an old one, add the new one and note the change:

```markdown
- Use Zod for validation — confirmed by human (session 1)
- ~~Use Zod for validation~~ Switched to Valibot per human request (session 3)
```

### Don't duplicate the task file
The task file tracks what's done (checkboxes). The session state tracks what you
know and what you decided. Don't repeat progress information that's already in
the task file — just reference the current position.

### Workflow controls must stay current
If `Validation Review Mode` or `Current Phase` changes, update the session state
immediately. These fields are workflow controls, not optional notes.

### Delete on feature completion
When a feature passes final verification and the human signs off, the session
state file has served its purpose. It can be deleted or archived — it should not
be committed to the main branch.
