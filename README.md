# ai-rules

Structured rules for AI-assisted feature development. Forces acceptance criteria,
validation-before-implementation, and human gates at critical decision points.

## The Problem

AI coding agents will happily generate code without a clear definition of "done",
skip validation, and mark their own work complete. This leads to features that
compile but don't work, tasks that are checked off but not verified, and scope
that silently drifts.

## The Solution

A set of mandatory rules that enforce:

1. **Human-approved acceptance criteria** before any code is written
2. **AI-generated validation steps** before each task is implemented
3. **Observable proof** of task completion (not self-assessment)
4. **Human gates** at critical decision points

## Quick Start

### Option 1: Git Subtree (recommended for shared projects)

```bash
# Add as a subtree
git subtree add --prefix=.ai-rules https://github.com/portaj/ai-rules.git main --squash

# Update later
git subtree pull --prefix=.ai-rules https://github.com/portaj/ai-rules.git main --squash
```

### Option 2: Git Submodule

```bash
git submodule add https://github.com/portaj/ai-rules.git .ai-rules
```

### Option 3: Just copy it

```bash
cp -r ai-rules/ /path/to/your/project/.ai-rules/
```

## Platform Wiring

After adding the rules to your project, wire them into your AI tool:

### Claude Code

Claude Code auto-discovers `AGENTS.md` files in subdirectories. No additional
configuration needed. The rules in `.ai-rules/AGENTS.md` will be automatically
loaded.

### Cursor

Add a rule file at `.cursor/rules/ai-rules.md`:

```markdown
Read and follow all rules in `.ai-rules/AGENTS.md` and the files it references
before beginning any feature work.
```

Or reference it in `.cursorrules`:

```
@file .ai-rules/AGENTS.md
```

### Windsurf

Add to `.windsurfrules`:

```
Before starting any feature work, read and follow the rules defined in
.ai-rules/AGENTS.md and all referenced rule files in .ai-rules/rules/.
```

### GitHub Copilot

Add to `.github/copilot-instructions.md`:

```markdown
## Development Rules

Follow the AI development rules defined in `.ai-rules/AGENTS.md`.
Read all referenced rule files before beginning feature work.
```

### Amp / Other Agents

Most agents accept a system prompt or project instructions file. Point them at:

```
.ai-rules/AGENTS.md
```

## Structure

```
.ai-rules/
  AGENTS.md                      # Entry point and core principles
  rules/
    01-workflow-overview.md       # End-to-end process with human gates
    02-prd.md                     # PRD generation and acceptance criteria
    03-task-generation.md         # Task decomposition with validation criteria
    04-validation-first.md        # Write validation before implementation
    05-task-execution.md          # Execute tasks, track progress, verify completion
  templates/
    prd.md                        # Blank PRD template
    tasks.md                      # Blank task list template
```

## The Two Types of Criteria

| | Acceptance Criteria | Validation Criteria |
|---|---|---|
| **Owner** | Human | AI |
| **When defined** | PRD phase (before tasks) | Pre-implementation (per task) |
| **What it answers** | "What does done mean?" | "How do we prove this task got us there?" |
| **Approval** | Required before any work | Human reviews if desired |
| **Granularity** | Feature-level | Task-level |
| **Mutability** | Only changed with human approval | AI can refine as understanding deepens |

## Extending for Your Organization

These rules are intentionally generic. Fork this repo to add:

- Organization-specific coding standards
- CI/CD pipeline validation steps
- Project management tool integration (Jira, Linear, etc.)
- Security and compliance checks
- Infrastructure-specific validation patterns

Keep extensions in a separate file (e.g., `rules/06-org-standards.md`) and
reference it from your fork's `AGENTS.md`.

## License

Apache-2.0
