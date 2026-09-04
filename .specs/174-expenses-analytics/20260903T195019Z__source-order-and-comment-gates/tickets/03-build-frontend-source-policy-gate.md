# 03. Build frontend source-policy gate

Spec: ../spec.md
Status: done
Blocked by: 01

## What to build

Provide independently tested frontend ordering and comment checks through the adapter selected by ticket 01, while keeping the ordinary `pnpm lint` gate disabled until legacy cleanup finishes.

This is horizontal lint infrastructure because runtime and test cleanup require one shared parser-backed contract and CSS scanner.

## Acceptance criteria

- [x] Adapter-independent logic implements the approved zero-incoming-edge traversal for function declarations, variable-bound functions/arrows, nested synthetic roots, JSX references, and class `this` calls.
- [x] The ordering logic excludes imports, other-object/computed calls, callback references used only as values, object-literal methods, and dynamic resolution.
- [x] JS/TS/TSX comment classification rejects prose line, block, and JSX comments and accepts only approved exact directives.
- [x] A CSS scanner rejects ordinary block comments and accepts only exact required legal/generated directives.
- [x] The selected Oxlint or standalone adapter reports actionable file, scope, and expected-before-actual/comment diagnostics with a nonzero exit.
- [x] `pnpm lint:source-policy` can audit the full frontend and can select `--runtime-files` or `--test-files` for independent cleanup verification.
- [x] Ordinary `pnpm lint` remains unchanged until ticket 11.
- [x] `artifacts/frontend-source-policy-audit.md` records exact runtime, test/mock, and CSS offense counts plus representative false-positive review results.
- [x] No application or test source is reordered and no legacy prose comment is removed in this ticket.

## TDD cases

- `A calls B then C; B calls D` — frontend logic test expects `A, B, D, C`; write the failing test before traversal logic.
- `callee is exported and declared before its caller` — frontend logic test expects an offense; write the failing test before root selection.
- `shared, disconnected, and cyclic functions` — logic tests prove deterministic first encounter and termination.
- `nested helper called by its enclosing body` — logic test proves the enclosing body acts as a synthetic root.
- `React and class syntax` — logic tests cover JSX component references and direct `this.method()` edges.
- `excluded frontend references` — logic tests cover imports, other objects, computed calls, value-only callbacks, and object literals.
- `frontend prose and directives` — classifier tests cover line, block, JSX, malformed-lookalike, and exact directive comments.
- `CSS prose and directives` — scanner tests cover ordinary comments and exact allowed headers.
- `process integration` — a fixture proves the selected adapter emits diagnostics and returns nonzero.

## Anchors

- `.oxlintrc.json:1-26` — current Oxlint configuration and generated API exclusion.
- `package.json:4-16` — commands that the source-policy audit and final gate must integrate with.
- `app/frontend/components/inline-cell-editing/InlineCellEditor.tsx:13-58` — representative TSX prose comments and sibling functions.
- `app/frontend/test/mocks/inertia.tsx:1-68` — representative test prose and locally calling helper functions.
- `app/frontend/styles/application/profitability.css:1-18` — representative CSS prose comments.
- `../artifacts/frontend-lint-adapter-feasibility.md` — adapter decision produced by ticket 01.
- `../spec.md:77-87` — complete approved frontend source-policy contract.

## Coordination notes

- Tickets 09 and 10 depend on the stable command selectors and consume the audit artifact. Do not activate the ordinary frontend lint gate here.

## Non-goals

- Do not add a parser dependency unless ticket 01 proved it necessary under the spec, alter application behavior, clean legacy source, or autocorrect declarations.

## Focused verification

- `mise exec -- pnpm exec vitest run tools/source-policy/frontend` — proves adapter-independent ordering, comment classification, CSS scanning, and process integration.
- `mise exec -- pnpm lint:source-policy` — produces the expected nonzero pre-cleanup audit whose results are recorded in the artifact.
