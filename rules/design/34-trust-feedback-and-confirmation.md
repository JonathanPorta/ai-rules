# Trust, Feedback, and Confirmation

## Purpose

Make system status visible, reduce anxiety, and prevent accidental harmful
actions.

## Apply this when

- designing any loading, scanning, syncing, deleting, publishing, or payment flow
- designing AI-assisted recommendations or summaries
- designing actions that change persistent state

## Required outputs

- progress model
- confirmation policy
- rollback or recovery note
- success and error states

## Rules

1. Show what the system is doing when work takes noticeable time.
2. Prefer named progress over anonymous spinners.
3. Use confirmation in proportion to risk.
4. Prefer undo for low-risk reversible actions.
5. For irreversible or high-consequence actions, communicate scope,
   consequence, and affected objects clearly.
6. Label AI-generated recommendations where user trust depends on it.
7. Success states should confirm what changed, not merely that something is done.
8. Error states should explain what the user can do next.

## Anti-patterns

- spinner without context
- vague copy like "continue" on dangerous actions
- warnings that feel dramatic but say nothing actionable
- error states that dead-end the flow

## Review questions

- does the user know what is happening right now
- does the user know what will happen next
- is the confirmation proportional to the risk
- can the user recover from mistakes

## Example

Instead of: "Processing..."
Use: "Scanning caches, downloads, and mail attachments..."
