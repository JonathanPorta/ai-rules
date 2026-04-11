# Design Memory and Consistency

## Purpose

Preserve recurring patterns and decisions so the product feels like one system
instead of a pile of individually attractive screens.

## Apply this when

- extending an existing product
- creating a design system or component library
- reviewing drift across screens or releases
- handing work between humans and AI sessions

## Required outputs

- reusable pattern notes
- decision log for important design choices
- consistency checks across sibling screens

## Rules

1. Reuse established patterns unless there is a clear reason to change them.
2. Record deviations intentionally instead of letting them accumulate.
3. Keep labels, placement, and state behavior consistent across sibling screens.
4. Preserve semantic color meaning over time.
5. Store design rationale, not only final screenshots.
6. When a new pattern is introduced, define where else it should or should not appear.
7. Prefer a small number of reliable patterns over many clever one-offs.

## Anti-patterns

- every flow inventing its own confirmation pattern
- similar cards with different interaction behavior
- changing visual meaning of colors across screens
- losing earlier decisions between sessions and re-debating them from scratch

## Review questions

- what existing pattern should this match
- what decision needs to be remembered later
- where is the product teaching users one behavior and then breaking that lesson
- is this a new pattern or an accidental inconsistency

## Example

If detail drawers open from the right everywhere else, a modal-on-click in one
screen should be treated as a deliberate exception or corrected.
