# User Journeys and State Inventory

## Purpose

Force the product to be designed as a working journey with explicit states,
rather than as disconnected happy-path screens.

## Apply this when

- defining flows
- reviewing product completeness
- designing multi-step or system-driven experiences
- critiquing an existing utility, dashboard, or workflow product

## Required outputs

- journey map for key flows
- state inventory for each major screen or flow
- recovery paths for failures and interruptions

## Rules

1. Map the key journey before polishing the screens.
2. Enumerate at least these states where applicable:
   - entry
   - loading
   - empty
   - partial
   - success
   - failure
   - destructive / confirmation
   - recovery
3. Distinguish between system-driven states and user-driven states.
4. Ensure every failure state has a next step.
5. Design for interrupted flows, not only clean runs.
6. Preserve context between summary and detail views.

## Anti-patterns

- designing only the default state
- spinner with no progress context
- error messages with no recovery path
- context loss when moving between screens

## Review questions

- what happens before this screen
- what happens after it
- what if the system is slow, empty, partial, or wrong
- how does the user recover from interruption or failure

## Example

A scan results screen is incomplete unless it also defines the states for first
run, in-progress, partial results, no findings, failed scan, and post-action
success.
