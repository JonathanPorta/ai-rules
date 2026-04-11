# Accessibility and Legibility

## Purpose

Ensure the interface remains readable, operable, and understandable across a
range of users, devices, and conditions.

## Apply this when

- designing any screen, component, or flow
- reviewing typography, contrast, motion, or target sizing
- translating visual direction into build-ready requirements

## Required outputs

- accessibility notes
- legibility checks
- interaction considerations beyond ideal conditions

## Rules

1. Meet contrast needs for text and critical controls.
2. Do not rely on color alone to convey meaning.
3. Ensure touch and click targets are comfortably usable.
4. Make keyboard flow and focus order coherent.
5. Use motion to support comprehension, not to create distraction.
6. Keep copy plain where the user is under stress or making decisions.
7. Preserve readability when content grows, localizes, or wraps.
8. Assume at least some users are tired, rushed, or unfamiliar.

## Anti-patterns

- faint gray text on decorative backgrounds
- tiny icon-only controls with no support text
- important status communicated only by color
- error copy that hides the actual next step

## Review questions

- can this be understood quickly under less-than-ideal conditions
- what fails if color disappears
- what fails if the user tabs instead of clicks
- does the wording reduce or increase cognitive load

## Example

A beautiful muted palette is not a success if users cannot distinguish warnings,
primary actions, or disabled controls.
