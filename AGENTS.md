# AI Development Rules

These rules govern how AI agents approach feature development in this project.
They are **mandatory** — not suggestions.

Read and internalize ALL rules before beginning any feature work.

## Required Rules

These rules are mandatory for all feature work. Read all of them before starting.

0. [Project Planning](rules/00-project-planning.md) — Phased planning for multi-feature projects
1. [Workflow Overview](rules/01-workflow-overview.md) — The end-to-end process
2. [PRD Generation](rules/02-prd.md) — How to produce a Product Requirements Document
3. [Task Generation](rules/03-task-generation.md) — How to decompose a PRD into tasks
4. [Validation-First Development](rules/04-validation-first.md) — Writing validation before code
5. [Task Execution](rules/05-task-execution.md) — How to implement and verify tasks
6. [Session State](rules/06-session-state.md) — Persisting context across sessions

## Domain Rule Sets

These rules are required **when the work includes user-facing UX, UI, flows,
IA, screen specs, design systems, or design critique**.

30. [Design Principles](rules/design/30-design-principles.md) — What makes a product feel coherent, trustworthy, and polished
31. [UX Brief and Intent](rules/design/31-ux-brief-and-intent.md) — Define the user, job, emotional goal, and success criteria
32. [Information Architecture](rules/design/32-information-architecture.md) — Organize navigation and content so it stays legible under growth
33. [User Journeys and State Inventory](rules/design/33-user-journeys-and-state-inventory.md) — Enumerate flows and states before polishing screens
34. [Trust, Feedback, and Confirmation](rules/design/34-trust-feedback-and-confirmation.md) — Make system status visible and risky actions proportionate
35. [Visual System and Hierarchy](rules/design/35-visual-system-and-hierarchy.md) — Create emphasis, rhythm, and visual coherence
36. [Screen Review and Critique](rules/design/36-screen-review-and-critique.md) — Evaluate screens with concrete review questions
37. [Accessibility and Legibility](rules/design/37-accessibility-and-legibility.md) — Ensure the interface is usable, readable, and robust
38. [Design Memory and Consistency](rules/design/38-design-memory-and-consistency.md) — Preserve recurring patterns and decisions over time

## Optional Rules (disabled by default)

These rules are only active when explicitly enabled below. To enable, move a rule
from the "available" list to the "enabled" list.

**Available:**
- [TDD Enforcement](rules/07-tdd-enforcement.md) — Red-then-green evidence requirement

**Enabled:**
<!-- Move rules here to activate them. Example: -->
<!-- - [TDD Enforcement](rules/07-tdd-enforcement.md) -->

## Core Principles

1. **Understand before you propose.** Before writing a PRD or suggesting changes,
   explore the codebase and produce a written analysis. Document what you found,
   what patterns exist, and what constraints you discovered. The human reviews this
   analysis BEFORE you propose solutions. Every misunderstanding caught here saves
   hours downstream.

2. **Nothing ships without acceptance criteria.** Every feature has human-approved
   acceptance criteria before any code is written.

3. **Validation before implementation.** For every task, define how you will prove
   it works BEFORE writing the code.

4. **Observable proof over self-assessment.** "It works" is not validation. Show a
   test passing, a command output, or a verifiable state change.

5. **Human owns acceptance, AI owns validation.** The human defines what "done"
   means. The AI defines how to prove each step got there.

6. **Fail loudly.** If validation fails, stop. Do not mark the task complete. Do
   not proceed to the next task. Report what failed and why.

7. **Scope is sacred.** Do not add, remove, or modify acceptance criteria without
   human approval. If you discover unplanned work, surface it — don't silently do it.

8. **Plan scales to scope.** Single feature? Go straight to PRD. Multi-feature
   project? Start with a phased project plan. Don't force heavyweight process on
   simple work, and don't skip planning on complex work.

9. **Preserve what you learn.** Maintain a session state file so that context
   loss — from compaction, session end, or conversation switch — does not mean
   knowledge loss. Decisions made by the human are especially expensive to lose.

10. **Design the state machine, not just the hero screen.** For user-facing work,
    spend effort on orientation, trust, progress visibility, edge states, and
    confirmation moments — not only on a polished happy path.
