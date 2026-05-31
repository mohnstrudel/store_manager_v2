# Codex Frontend Architecture Guide

Use this document as a reusable architecture brief for Codex on the React and browser-side parts of this repo. It is based on a production-style frontend that organizes UI work around pages, shared components, local state, and explicit backend-provided data contracts. For backend domain work, use the Rails architecture guide instead.

## AGENTS.md Snippet

```md
# Frontend Architecture

Design frontend code around page boundaries, shared components, client-side state, and explicit server data contracts.

- Treat `app/frontend/pages` as the composition root for screen-level UI.
- Keep reusable UI pieces in `app/frontend/components` and browser helpers in `app/frontend/lib`.
- Keep hooks, utilities, and state management small and single-purpose.
- Prefer composition and explicit props over deep, cross-cutting abstractions.
- Treat backend payloads as a contract. If the page needs a new prop, route helper, or response field, coordinate that seam explicitly.
- Keep browser interaction code literal and close to the widget that owns it.
- For risky UI changes, add focused component tests or browser-level feature coverage that exercise visible behavior.
```

## Core Rules

- Use this guide for React pages, shared components, hooks, client-side utilities, and browser interaction widgets.
- Keep backend/domain rules out of UI components unless the contract itself changes.
- Page components should mainly compose data, layout, and local interaction state.
- Shared components should be reusable across pages without knowing backend persistence details.
- Keep client-side state local to the component or hook that owns the interaction.
- Prefer explicit props and small helper functions over heavy abstraction layers.
- Use the frontend testing guide for component tests and browser-level UI coverage.
- If a frontend change needs new backend data or routes, coordinate with the backend Rails guide separately rather than importing backend placement rules into the component layer.

## What Codex Often Gets Wrong

- Do not move backend domain rules into React just because the UI needs them.
- Do not create a shared component for a one-screen-only pattern unless the reuse is real.
- Do not overgeneralize page components into framework-like abstractions.
- Do not hide backend contract changes inside component code; update the backend seam explicitly.
- Do not skip visible-behavior tests when the UI is risky or interaction-heavy.
