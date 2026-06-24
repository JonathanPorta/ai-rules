# Codebase Analysis — Rubric and Example

The Codebase Analysis is the first artifact produced when authoring a PRD.
Its purpose is to surface what you actually read, what patterns you saw,
what constraints you discovered, and what assumptions you are making — so
the human can correct you *before* you propose a solution.

This is the highest-leverage gate in the workflow. Misunderstandings caught
here cost minutes; the same misunderstandings caught after implementation
cost hours.

The required structure (Explored / Relevant Patterns / Constraints /
Assumptions) lives in `.ai-rules/rules/02-prd.md`. This reference covers
rubric, failure modes, and a worked example to calibrate taste.

## Rubric

A good Codebase Analysis is:

- **Specific.** File paths, not "the API layer." Module names, not "the
  database stuff." If you did not read it, do not claim it.
- **Short.** One line per finding. The goal is fast human review, not
  comprehensive documentation.
- **Surfacing.** Call out constraints, missing tooling, large files,
  shared ownership, undocumented dependencies — anything that will shape
  implementation choices.
- **Honest about assumptions.** If you are inferring how something works,
  flag it. The human reviewing it knows the codebase better than you do.

## Common failure modes

- **Phantom file references.** Citing files you did not actually open.
  If your tool log doesn't show you reading it, do not list it.
- **Vague findings.** "The codebase uses React." Useless. Compare with:
  "React 18, no form library, validation hand-rolled per-component."
- **Missing assumptions.** Silently inferring "we can alter the users
  table" instead of flagging it as an assumption. The human owns scope.
- **Padding for length.** Listing every file in the repo. Stay relevant
  to the feature in question.
- **Skipping the gate.** Producing the analysis and immediately proposing
  a solution in the same turn. Stop after the analysis; ask the human to
  confirm before continuing.
- **Conflating "I read it" with "I understood it."** Reading a 500-line
  handler is not the same as knowing its invariants. Flag uncertainty as
  an assumption rather than restating code as understanding.

## Worked example

> ### Codebase Analysis: User Profile Bio Field
>
> **Explored**
> - `src/api/users.ts` — Express REST routes for /users; 580 lines, includes inline validation
> - `src/db/schema.ts` — Drizzle ORM; `users` table has id, email, name, created_at — no bio column
> - `src/components/ProfileForm.tsx` — React form, hand-rolled validation, no form library
> - `package.json` — Jest configured, 85% coverage threshold; no migration tool listed
> - `tests/api/users.test.ts` — 12 tests covering create / update / delete; uses supertest
>
> **Relevant Patterns**
> - API routes follow `src/api/<resource>.ts` naming
> - Validation is inline in each handler; no shared validation utilities
> - Tests live under `tests/api/` mirroring `src/api/`
> - Auth via JWT middleware at `src/middleware/auth.ts`
>
> **Constraints Discovered**
> - No database migration tooling — schema changes happen via hand-written SQL committed to `db/migrations/`
> - `src/api/users.ts` is already 580 lines; adding more handlers here grows technical risk
> - Bio length is not bounded anywhere in current code; need to decide a cap
>
> **Assumptions (need human confirmation)**
> - The existing inline-validation pattern should continue (vs. introducing Zod)
> - No mobile-client compatibility constraints on the response shape
> - `users` table is single-team owned (no cross-team migration coordination)
> - 500-character bio cap is reasonable; will confirm in clarifying questions

Each "Explored" line carries a one-phrase fact you can defend if asked.
Each "Constraint" is something that will shape implementation. Each
"Assumption" is a place the human can correct you before the PRD locks in.
