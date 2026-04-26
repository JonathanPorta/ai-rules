# Phase-Gate Audits

Before moving between phases, marking work complete, preparing a PR
description, or handing control back to the human after substantial work,
the agent must run a phase-gate audit.

The audit exists to catch drift between:

- the active AI rules
- project specs
- PRDs
- phase documents
- task lists
- state documents
- implementation notes
- current repository changes

## Required Audit Triggers

Run a phase-gate audit:

1. Before moving from one documented phase to the next.
2. Before marking any task, checklist item, milestone, or phase as done.
3. Before generating a PR description.
4. Before generating release notes.
5. After any large implementation chunk touching multiple files or concepts.
6. After recovering from an error, failed test, failed command, merge
   conflict, or unexpected state.
7. Before ending a session if the work is incomplete.
8. Whenever the human asks to continue, move on, go to the next phase, wrap
   up, or ship it.

If the work has no formal phases, treat each coherent implementation chunk
as a phase.

## Phase-Gate Audit Checklist

Before proceeding, re-review:

- the active AI rules
- project specs
- PRD
- phase documents
- task lists
- state documents
- implementation notes
- current repository changes

Then report:

1. **Rules compliance** — confirm whether the work follows the active
   `ai-rules`.
2. **False completions** — call out anything listed as done that is not
   actually done.
3. **Missed required work** — call out anything that was supposed to be done
   but has not been done.
4. **Documentation drift** — call out anything implemented differently from
   the state, task, PRD, spec, phase plan, or other documentation.
5. **Untracked changes in direction** — call out any decision, shortcut,
   assumption, or scope change that should be documented before moving on.
6. **Verification status** — list what was actually verified, how it was
   verified, and what remains unverified.

## Required Audit Output Format

Use this structure:

```md
### Phase-Gate Audit

**Result:** PASS / PASS WITH WARNINGS / BLOCKED

**Rules compliance:**
- ...

**Listed done but not actually done:**
- ...

**Required but not done:**
- ...

**Done differently than documented:**
- ...

**Documentation/state updates needed:**
- ...

**Verification performed:**
- ...

**Recommended next action:**
- ...
```

## Blocking Behavior

The agent must not proceed to the next phase while the audit result is
`BLOCKED`.

If the audit result is `PASS WITH WARNINGS`, the agent may proceed only
after explicitly calling out the warnings and the risk of continuing.

## Done Means Verified

The agent must not mark work as done merely because code was written.

Work may only be marked done when:

- the documented acceptance criteria have been satisfied, or
- the deviation is explicitly documented, or
- the remaining gap is clearly listed as incomplete.

## Lightweight Checkpoint Audit

For smaller chunks, use:

```md
### Lightweight Checkpoint Audit

**What changed:**
- ...

**Requirement satisfied:**
- ...

**Still incomplete:**
- ...

**Possible drift:**
- ...

**Check before continuing:**
- ...
```
