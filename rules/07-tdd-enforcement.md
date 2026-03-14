# TDD Enforcement (Optional)

> **This rule is optional.** It is only active when listed in the "Optional Rules
> (enabled)" section of your project's `AGENTS.md`. Teams that do not practice
> TDD or work on projects without test infrastructure should skip this rule.

## Purpose

Rule [04-validation-first.md](04-validation-first.md) requires writing validation
steps before implementation. This rule goes further: when validation includes
automated tests, it requires **evidence of red-then-green TDD** — proving that
tests failed before implementation and passed after.

Without this evidence, there is no way to distinguish "test written before code"
from "test written to match existing code." The latter is not TDD and does not
provide the same safety guarantees.

## The TDD Evidence Requirement

When a task involves writing automated tests, the validation results MUST include
both phases:

### Red Phase (before implementation)

Run the test suite AFTER writing tests but BEFORE writing implementation code.
Capture the output showing failures:

```markdown
**Red phase:**
$ npm test -- users.test.ts

FAIL  src/api/users.test.ts
  ✕ returns 422 when email is invalid (3ms)
  ✕ returns 422 when name is empty (1ms)
  ✕ returns 200 with valid input (2ms)

Tests: 3 failed, 3 total
```

### Green Phase (after implementation)

Run the same test suite AFTER implementing the code. Capture the output showing
all tests pass:

```markdown
**Green phase:**
$ npm test -- users.test.ts

PASS  src/api/users.test.ts
  ✓ returns 422 when email is invalid (4ms)
  ✓ returns 422 when name is empty (2ms)
  ✓ returns 200 with valid input (8ms)

Tests: 3 passed, 3 total
```

### Validation Results Table

Include TDD evidence as a row in the standard validation results table:

```markdown
| # | Check                           | Result  | Notes              |
|---|---------------------------------|---------|--------------------|
| 1 | Tests fail before implementation | PASS   | 3/3 red            |
| 2 | Tests pass after implementation  | PASS   | 3/3 green          |
| 3 | No test modifications after red  | PASS   | Tests unchanged    |
| 4 | TypeScript compiles              | PASS   |                    |
| 5 | Lint passes                      | PASS   |                    |
```

## Rules

### Tests must not be modified after the red phase
Once a test is written and shown to fail, do not modify the test to make it pass.
Only modify the implementation. If a test needs to change after seeing the red
output, explain why:

> "Modified test 2 after red phase: the original assertion used the wrong HTTP
> status code (expected 400, should be 422 per the PRD). This is a spec
> correction, not a test-to-match-code change."

### Handle cases where red is not possible
Sometimes tests cannot fail first:
- **Existing functionality:** Tests for already-working behavior. Explain: "This
  test validates existing behavior that was not previously tested."
- **Configuration/setup tasks:** No meaningful test to write. Explain: "This task
  is infrastructure setup with no testable behavior."
- **No test runner:** Flag per [05-task-execution.md](05-task-execution.md):
  "No test infrastructure. Manual validation only."

In these cases, document WHY you could not show red-then-green. Silence is not
acceptable — always explain.

### Do not fake evidence
If you wrote implementation before tests (even accidentally), do not delete the
implementation to recreate a red phase. Instead, be honest:

> "Implementation was written before tests for this task. Tests were added after
> and pass, but TDD sequence was not followed. This is a deviation."

Honesty enables the human to decide whether to accept or request a redo.

## Optional: Automated TDD Check Script

The `scripts/tdd-check.sh` script provides a lightweight automated check. It
compares git commit timestamps to verify that test files were committed before
or at the same time as implementation files.

### Usage

```bash
# Check a single file pair
./scripts/tdd-check.sh src/api/users.ts src/api/users.test.ts

# Output (pass)
# ✅ Test file was committed before or with implementation

# Output (fail)
# ⚠️  Implementation was committed before tests — TDD violation
# Implementation: src/api/users.ts (committed 2025-03-10 14:30)
# Test file:      src/api/users.test.ts (committed 2025-03-10 14:45)
```

### Limitations
- Only checks commit timestamps, not edit order within a single commit
- Requires git history (won't work before first commit)
- Does not detect test modifications after red phase
- This is a supplementary check, not a replacement for the evidence requirement

### Integration
Include the script output in the validation results table as an additional row:

```markdown
| # | Check                            | Result  | Notes             |
|---|----------------------------------|---------|-------------------|
| 6 | tdd-check.sh (timestamp verify)  | PASS    | test before impl  |
```
