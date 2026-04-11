# Design Principles

## Purpose

Define what makes user-facing work feel coherent, useful, and trustworthy.

## Apply this when

- designing new user-facing products or features
- critiquing existing UX/UI
- generating concepts, flows, or screen directions
- building design systems or interaction patterns

## Required outputs

- explicit user and task understanding
- flow and state awareness
- rationale for where polish is concentrated

## Rules

1. **Orient the user quickly.** Every screen should answer where the user is,
   what the system is showing, and what can be done next.
2. **Optimize for confidence, not decoration.** A product feels premium when it
   reduces uncertainty.
3. **Spend polish where users notice risk and progress.** First touch, loading,
   review, confirmation, success, and recovery deserve disproportionate care.
4. **Separate browse mode from inspect mode.** Summary and detail should not
   fight each other.
5. **Design the full state model.** Loading, empty, partial, success, failure,
   confirmation, and recovery states are part of the product.
6. **Keep hierarchy legible.** One hero region per screen. Primary action should
   be obvious.
7. **Use visual intensity intentionally.** Strong gradients, saturation, and
   motion should mean something.
8. **Earn trust before destructive action.** Review before delete. Explain scope
   and consequence.

## Anti-patterns

- hero-only design with no edge states
- every card screaming for attention
- destructive actions hidden behind vague labels
- ornamental UI that obscures system status

## Review questions

- what should the user understand in the first three seconds
- where does the screen spend its visual energy
- what happens when things go wrong
- what makes the user trust the interface

## Example

A system utility should not only look clean. It should make the user feel safe
while taking actions that might affect persistent data.
