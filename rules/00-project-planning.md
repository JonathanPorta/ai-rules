# Project Planning Rules

## When to Use This Rule

Use project-level planning when the scope involves **multiple features or
workstreams** that need coordination. Examples:

- "Build a user dashboard" (authentication + profile + activity feed + notifications)
- "Migrate from REST to GraphQL" (schema design + resolver implementation + client migration + deprecation)
- "Launch a new service" (infrastructure + API + integrations + monitoring)

**Skip this rule** for single-feature work. Go directly to
[02-prd.md](02-prd.md) instead.

## The Hierarchy

```
Project Plan
├── Phase 1: <Objective>
│   ├── Feature A → PRD → Tasks → Implementation
│   └── Feature B → PRD → Tasks → Implementation
├── Phase 2: <Objective>
│   ├── Feature C → PRD → Tasks → Implementation
│   └── Feature D → PRD → Tasks → Implementation
└── Phase 3: <Objective>
    └── Feature E → PRD → Tasks → Implementation
```

Each feature within a phase follows the full workflow defined in
[01-workflow-overview.md](01-workflow-overview.md) — PRD, acceptance criteria,
task generation, validation-first implementation.

## Process

### Step 1: Project Brief (Human + AI)

The human provides the high-level vision. This can be anything from a sentence
to a detailed document. The AI then produces a **Project Brief** — a lightweight
document (NOT a PRD) that captures the overall initiative.

```markdown
# Project Brief: <Project Name>

## Vision
One paragraph. What we are building and why it matters.

## Success Metrics
How we will know the project succeeded (not per-feature — project-level).
- Metric 1
- Metric 2

## Constraints
- Timeline, budget, team size, technology restrictions
- Non-negotiable requirements (compliance, backward compatibility, etc.)

## Known Risks
- Risk 1: <description> — Mitigation: <approach>
- Risk 2: <description> — Mitigation: <approach>
```

The AI presents the brief and asks:

> "Does this brief accurately capture the project scope and constraints?
> Modify anything before I propose phases."

**Wait for approval.** ← GATE

### Step 2: Phase Decomposition (AI proposes, Human approves)

The AI proposes phases based on:

1. **Dependency analysis** — what must exist before something else can be built.
2. **Risk ordering** — high-risk or high-uncertainty work goes earlier.
3. **Value delivery** — each phase should deliver something usable or testable,
   not just "infrastructure."

For each phase, define:

```markdown
## Phase 1: <Phase Name>

**Objective:** What is true when this phase is complete.

**Entry Criteria:**
- What must be done before this phase can start
- (Phase 1 typically has none or "project kickoff complete")

**Exit Criteria:**
- Observable, verifiable conditions that prove this phase is done
- These are NOT the same as per-feature acceptance criteria
- Think: "what can we demo/test/ship after this phase?"

**Features:**
- Feature A: <one-line description>
- Feature B: <one-line description>

**Dependencies:**
- Feature B depends on Feature A (shared auth module)
- Feature A has no internal dependencies
```

Present the full phase plan and ask:

> "Here is the proposed phased breakdown. Review the phases, ordering, and
> dependencies. Respond with changes or 'Go' to proceed."

**Wait for approval.** ← GATE

### Step 3: Dependency Map (AI generates)

Produce a dependency map showing cross-feature and cross-phase relationships:

```markdown
## Dependency Map

Feature A (Phase 1) ──→ Feature C (Phase 2)  [shared auth module]
Feature A (Phase 1) ──→ Feature D (Phase 2)  [user data model]
Feature B (Phase 1) ──→ Feature E (Phase 3)  [design system components]
Feature C (Phase 2) ─┐
Feature D (Phase 2) ─┴→ Feature E (Phase 3)  [all core features required]
```

This map is maintained throughout the project. When a feature changes, the AI
checks the dependency map for downstream impacts.

### Step 4: Execute Phases Sequentially

For each phase:

1. Generate PRDs for each feature in the phase (per [02-prd.md](02-prd.md)).
   Features within a phase can be PRD'd in parallel if they are independent.
2. Get acceptance criteria approved for each PRD. ← GATE (per feature)
3. Generate task lists for each feature (per [03-task-generation.md](03-task-generation.md)).
4. Implement features following [04-validation-first.md](04-validation-first.md)
   and [05-task-execution.md](05-task-execution.md).
5. Verify each feature against its acceptance criteria. ← GATE (per feature)

### Step 5: Phase Gate Review (Human)

When all features in a phase are complete:

1. AI presents a **Phase Completion Report**:

```markdown
## Phase 1 Completion Report

### Exit Criteria Verification
| # | Exit Criterion                         | Evidence                    | Status |
|---|---------------------------------------|-----------------------------|--------|
| 1 | Auth system handles login/logout/refresh | 12 tests pass, manual verified | MET    |
| 2 | Design system covers all core components | 8 components, Storybook live   | MET    |

### Features Completed
| Feature | ACs Met | ACs Total | Status    |
|---------|---------|-----------|-----------|
| Auth overhaul | 5 | 5    | Complete  |
| Design system | 4 | 4    | Complete  |

### Discovered Issues
- [Issue 1]: <description> — Recommended: address in Phase 2
- [Issue 2]: <description> — Recommended: add as Phase 3 feature

### Impact on Remaining Phases
- Phase 2 can proceed as planned (no dependency changes)
- Phase 3 may need a new feature for [Issue 2]
```

2. **Human reviews and decides:** ← GATE
   - Proceed to next phase as planned?
   - Adjust scope of upcoming phases?
   - Re-prioritize based on learnings?

### Step 6: Project Completion

When all phases are complete:

1. AI produces a **Project Summary** mapping the original success metrics to
   evidence.
2. AI lists all follow-up items discovered during the project.
3. Human confirms project completion or identifies remaining work.

## File Organization

```
tasks/
  project-plan.md                     <- The master plan (phases, dependencies)
  phase-1/
    prd-auth-overhaul.md
    tasks-auth-overhaul.md
    prd-design-system.md
    tasks-design-system.md
  phase-2/
    prd-user-profile.md
    tasks-user-profile.md
    prd-activity-feed.md
    tasks-activity-feed.md
  phase-3/
    prd-search.md
    tasks-search.md
```

## Rules

### Phase ordering is not arbitrary
Every phase must justify its position based on dependencies, risk, or value
delivery. "We will do it in Phase 2" is not a justification. "Phase 2 because
it depends on the auth module from Phase 1" is.

### Phases deliver value
Every phase should produce something demonstrable. Avoid phases that are purely
"setup" or "infrastructure" with no visible outcome. If infrastructure is
needed, pair it with a feature that uses it.

### Scope changes propagate
If a feature's acceptance criteria change, check the dependency map. If the
change affects downstream features, flag it:

> "AC-2 for Feature A changed. This impacts Feature C (Phase 2) which depends
> on the user data model. Feature C's PRD will need updating before
> implementation. Proceed with this change?"

### No phase skipping
Complete Phase N before starting Phase N+1, unless phases are explicitly marked
as independent. The phase gate review is mandatory.

### Single-feature escape hatch
If the project turns out to be simpler than expected (only one real feature),
collapse the project plan into a single PRD workflow. Do not force phased
structure where it adds no value.
