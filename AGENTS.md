# AI Development Rules

These rules govern how AI agents approach feature development in this project.
They are **mandatory** — not suggestions.

Read and internalize ALL rules before beginning any feature work.

## Rule Index

0. [Project Planning](rules/00-project-planning.md) — Phased planning for multi-feature projects
1. [Workflow Overview](rules/01-workflow-overview.md) — The end-to-end process
2. [PRD Generation](rules/02-prd.md) — How to produce a Product Requirements Document
3. [Task Generation](rules/03-task-generation.md) — How to decompose a PRD into tasks
4. [Validation-First Development](rules/04-validation-first.md) — Writing validation before code
5. [Task Execution](rules/05-task-execution.md) — How to implement and verify tasks

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
