# Codex Frontend Testing Guide

Use this document for component and browser-level test strategy for the React and browser-side parts of this repo. It is based on a frontend that relies on small page components, shared UI pieces, and visible interaction contracts.

## AGENTS.md Snippet

```md
# Frontend Testing

Test frontend code at the narrowest seam that still reflects user-visible behavior.

- Use Vitest and Testing Library for page components, shared components, and local utilities.
- Mock backend bridges such as `@inertiajs/react` or other data adapters when the component only needs props or navigation helpers.
- Keep page tests next to the page source and shared component tests next to the component source.
- Use browser-level feature specs for high-risk flows such as dialogs, drag and drop, file uploads, geometry-sensitive layouts, or multi-step client-side interactions.
- Treat open/closed state, loading indicators, repeated actions, and visible state changes as first-class assertions.
- If a frontend change also changes the backend response contract, add the matching backend request or integration test separately.
```

## Core Rules

- Test page components as component-level UI contracts, not as mini integration tests.
- Mock the data bridge at the edge so component tests stay fast and deterministic.
- Keep tests close to source: page tests beside pages, shared component tests beside shared components.
- Use browser-level feature specs for the user-visible risks that unit tests cannot cover well.
- Prefer a focused browser-level feature spec over guesswork when the UI detail itself is the risky part.
- If the frontend change also changes backend props, routes, or response shape, add the matching backend test separately.

## What Codex Often Gets Wrong

- Do not use browser tests for simple component rendering that a unit test already covers well.
- Do not stop at component tests when the visible interaction is what is actually risky.
- Do not let backend request specs substitute for component-level UI coverage.
- Do not add brittle screenshot tooling before trying a focused browser-level feature spec.
