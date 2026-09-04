# 10. Clean frontend tests and mocks

Spec: ../spec.md
Status: done
Blocked by: 03

## What to build

Make frontend test files, test factories, setup, and mocks satisfy depth-first declaration order and the no-prose-comment policy while preserving test behavior and shared mock contracts.

## Acceptance criteria

- [x] `pnpm lint:source-policy -- --test-files` reports no ordering or prose-comment offenses.
- [x] Shared Inertia and component mocks retain their exports, call-reset behavior, helper semantics, and structural type contracts.
- [x] Test helper movement does not change setup timing, mock initialization, module scope, example behavior, or coverage.
- [x] Existing expectations and scenarios are not weakened or removed as a shortcut.

Test-first does not apply because this is an approved behavior-neutral cleanup of test source. The complete Vitest run is the verification seam because shared mocks affect many suites.

## Anchors

- `app/frontend/test/mocks/inertia.tsx:1-100` — concentrated prose and shared helper call relationships.
- `app/frontend/test/mocks/resourceForm.tsx:1-68` — representative shared form mock.
- `app/frontend/pages/PurchaseItems/Index.test.tsx:53-63` — representative local render helper.
- `../artifacts/frontend-source-policy-audit.md` — exact test and mock offenses produced by ticket 03.

## Coordination notes

- Safe to run in parallel with ticket 09 after ticket 03. This ticket owns `app/frontend/test`, `app/frontend/test/setup.ts`, test factories, and `*.test.ts`/`*.test.tsx` files only.

## Non-goals

- Do not change runtime source, test expectations, test coverage, mock contracts, generated API files, or application behavior.

## Focused verification

- `mise exec -- pnpm lint:source-policy -- --test-files` — proves frontend test and mock source policy is clean.
- `mise exec -- pnpm exec vitest run` — proves the complete frontend suite retains its behavior.
- `mise exec -- pnpm exec tsc --noEmit` — catches declaration and initialization mistakes in test source.
- `mise exec -- pnpm exec oxfmt --check app/frontend` — proves cleanup preserves frontend formatting.
- `git diff --check -- app/frontend` — catches malformed cleanup edits.
