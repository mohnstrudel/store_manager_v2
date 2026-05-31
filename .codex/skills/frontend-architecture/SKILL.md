---
name: frontend-architecture
description: Design or refactor the React and browser-side UI in this Rails app toward small page components, reusable UI pieces, explicit props, and focused interaction boundaries. Use when planning app/frontend file layout, page composition, shared components, hooks, browser-side widgets, or frontend test strategy. Do not use this skill for backend model, controller, or job work; use `rails-domain-architecture` instead.
---

# Frontend Architecture

## Quick Start

- In this repo, treat `frontend-architecture` as the default starting skill for React pages, shared components, hooks, and browser-side interaction work.
- If the task also changes backend contracts, routes, or persisted data, coordinate that seam separately with `rails-domain-architecture` instead of pulling backend rules into the UI layer.
- Read `../../codex-frontend-architecture.md` before proposing a new UI structure or refactoring an existing one.
- Read `../../codex-frontend-testing.md` when the task is about component tests or browser-level interaction coverage.
- Start by identifying whether the work is a page, shared component, hook, utility, or browser-side widget.
- Treat backend-provided props and route contracts as the UI boundary, not as an excuse to import backend architecture into the component layer.

## Default Workflow

1. Choose the screen or widget boundary first.
2. Keep page components small and use them as composition roots.
3. Keep shared components reusable and explicit about their props.
4. Keep hooks and local utilities single-purpose and close to the behavior they own.
5. Keep browser-side state local to the widget that owns the interaction.
6. Prefer literal, readable component structure over abstraction-heavy mini-frameworks.
7. Use focused component tests and browser-level feature coverage when the UI risk is visible or interactive.
8. Coordinate backend contract changes separately instead of forcing backend architecture rules into frontend code.

## Placement Heuristics

- page-level composition -> `app/frontend/pages/<Resource>/<Page>.tsx`
- shared UI building block -> `app/frontend/components/<Name>.tsx`
- page-specific helper or utility -> `app/frontend/lib/<name>.ts`
- component test -> `app/frontend/pages/<Resource>/<Page>.test.tsx` or alongside the shared component
- browser interaction widget -> the smallest client-side module that owns the behavior

## What Codex Often Gets Wrong

- Do not move backend domain rules into React just because the UI needs data.
- Do not create a shared component for a one-screen-only pattern unless the reuse is real.
- Do not add global state or a complex abstraction before the local composition path has been exhausted.
- Do not hide backend contract changes inside component code; update the backend seam explicitly.
- Do not skip visible-behavior tests when the UI is risky or interaction-heavy.
