# 09. Clean frontend runtime and CSS

Spec: ../spec.md
Status: done
Blocked by: 03

## What to build

Make non-test frontend JavaScript/TypeScript/TSX and all covered CSS satisfy depth-first declaration order and the no-prose-comment policy without changing rendering, interaction, accessibility, styling, or browser behavior.

## Acceptance criteria

- [x] `pnpm lint:source-policy -- --runtime-files` reports no ordering or prose-comment offenses.
- [x] Covered CSS reports no ordinary block comments.
- [x] Components, hooks, utilities, entrypoints, and styles retain their existing public contracts and runtime behavior.
- [x] Declaration moves preserve React hook order, initialization order, imports, types, constants, and unrelated statements.
- [x] JSX comments are removed without changing rendered content or markup structure.
- [x] Generated frontend API files remain untouched and excluded.

Test-first does not apply because this is an approved behavior-neutral cleanup. Vitest and TypeScript are the verification seams for declaration movement; comment-only and CSS edits require lint, formatting, and diff inspection.

## Anchors

- `app/frontend/components/inline-cell-editing/InlineCellEditor.tsx:13-58` — representative runtime prose and sibling component declarations.
- `app/frontend/styles/application/profitability.css:1-18` — representative CSS section and explanatory comments.
- `app/frontend/pages/Sales/Show/Details.tsx:74-210` — representative file with many locally related functions.
- `../artifacts/frontend-source-policy-audit.md` — exact runtime and CSS offenses produced by ticket 03.

## Coordination notes

- Safe to run in parallel with ticket 10 after ticket 03. This ticket must not edit `*.test.*` files or `app/frontend/test`.

## Non-goals

- Do not change UI behavior, styling values, accessibility, generated API files, tests/mocks, imports, React hook order, or application contracts.

## Focused verification

- `mise exec -- pnpm lint:source-policy -- --runtime-files` — proves runtime JS/TS/TSX and CSS source policy is clean.
- `mise exec -- pnpm exec vitest run` — catches runtime behavior regressions across affected components and utilities.
- `mise exec -- pnpm exec tsc --noEmit` — catches declaration and initialization mistakes.
- `mise exec -- pnpm exec oxfmt --check app/frontend` — proves cleanup preserves frontend formatting.
- `git diff --check -- app/frontend` — catches malformed cleanup edits.
