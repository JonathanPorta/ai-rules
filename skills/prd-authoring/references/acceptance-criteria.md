# Acceptance Criteria — Rubric and Example

Acceptance criteria define what "done" means for a feature, in terms a
human can verify by inspection or by running a specific test. They are
the contract between the human and the implementation phase. Get them
right and the rest of the workflow has a sharp target; get them wrong
and every downstream artifact drifts.

The required AC numbering and format lives in `.ai-rules/rules/02-prd.md`.
This reference covers rubric, failure modes, and a worked example to
calibrate taste.

## Rubric

A good acceptance criterion is:

- **Verifiable.** A human looking at the running system can answer "yes,
  this criterion is satisfied" or "no, it isn't" without judgment calls.
- **Specific.** Include concrete values, status codes, behaviors, error
  messages, or observable outcomes. Numbers beat adjectives.
- **Testable.** You can describe — manually or in code — exactly what
  observation would verify the criterion.
- **Atomic.** One claim per criterion. Compound criteria ("validates input
  and persists changes and shows a toast") hide failures and resist
  red/green status.
- **Behavioral, not prescriptive.** Describes *what* the system does, not
  *how* it is implemented. "Uses Zod for validation" is not an AC;
  "rejects payloads with extra fields" is.
- **Stable.** Once approved, identifiers (`AC-1`, `AC-2`, …) do not
  change. Downstream tasks and verification tables reference them.

## Common failure modes

- **"Works correctly."** A literal example of an unverifiable AC. There
  is no observation that distinguishes "works correctly" from "does not."
- **"Has proper error handling."** Which errors? Surfaced how? At what
  layer? Sharpen into specific cases: "returns 422 with field-level
  errors when X is missing", "shows toast on 5xx with retry button".
- **"Is performant."** No threshold. Replace with "P95 latency under
  200ms at 100 RPS" or another measurable bar.
- **Implementation leakage.** Criteria that prescribe a specific function,
  library, or file. Describe behavior, not technology.
- **Compound criteria.** "Submits the form, validates input, persists the
  result, and shows a toast." Split into one AC per observable behavior.
- **Silent acceptance of vague human input.** When the human supplies a
  fuzzy criterion, do not paste it verbatim into the PRD. Ask them to
  sharpen it, proposing concrete language for review.

## When the human gives you vague criteria

Push back. Propose sharper language for them to accept or adjust:

> AC-3 currently says "handles errors gracefully." That is not verifiable
> as written. Which errors should it handle, and what should the user see
> for each? For example: "When the upstream API returns 5xx, the UI shows
> a non-blocking toast with a retry button, and the page state is
> preserved." Want to go with that, or adjust?

Do not soften vague criteria into vague-but-prettier criteria. Replace
adjectives with observations.

## Worked example

**Before sharpening — what the human first said:**

> - Users should be able to add a bio.
> - The bio should be reasonable length.
> - It should handle errors.

**After sharpening — verifiable ACs:**

> - [ ] AC-1: A signed-in user can submit a bio of up to 500 characters
>       via `PATCH /users/me` and the value is persisted across page reloads.
> - [ ] AC-2: Submitting a bio longer than 500 characters returns HTTP 422
>       with a field-level error `{ "bio": "must be 500 characters or fewer" }`
>       and the UI displays "Bio must be 500 characters or fewer" inline
>       under the field.
> - [ ] AC-3: Bio is escaped on read; a saved bio containing `<script>`
>       renders as literal text on the profile page, not as executable
>       script.
> - [ ] AC-4: When `PATCH /users/me` returns HTTP 5xx, the UI shows a
>       non-blocking toast with the message "Couldn't save your changes —
>       try again?" and a Retry button; form values are preserved.
> - [ ] AC-5: The bio field appears in the response of `GET /users/me`
>       when set, and is omitted (not `null`) when never set.

Each criterion can be observed by a human, expressed as a test, and
marked done or not done without judgment. None prescribes a library or
file layout. None hides a compound claim. Each is independently failable.

## Numbering and stability

Use `AC-1`, `AC-2`, … sequentially. Once the human approves them, the
identifiers are frozen — downstream task lists and the final verification
table reference them by ID. Adding criteria mid-implementation requires
returning to the PRD gate; do not add silently.
