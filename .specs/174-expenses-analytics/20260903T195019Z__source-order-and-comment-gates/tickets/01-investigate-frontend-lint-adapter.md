# 01. Investigate frontend lint adapter

Spec: ../spec.md
Status: done
Blocked by: none

## What to build

Produce evidence that the pinned Oxlint JavaScript plugin API can expose every syntax and comment surface required by the approved frontend contract, or establish the approved standalone-Node fallback before implementation begins.

This is a horizontal investigation because Oxlint marks the required extension API alpha; frontend implementation cannot choose a safe adapter without a disposable compatibility probe.

## Acceptance criteria

- [x] A disposable plugin proves whether Oxlint 1.69 provides function declarations, variable-bound functions and arrows, nested lexical scopes, JSX component references, class methods, direct calls, source order, line comments, block comments, and JSX comments.
- [x] The probe confirms whether rule diagnostics produce a nonzero exit through the repository's Node 24 and pnpm toolchain.
- [x] CSS comment coverage is assessed separately because Oxlint does not lint CSS through the JavaScript rule API.
- [x] `artifacts/frontend-lint-adapter-feasibility.md` records the exact commands, observed API shapes, supported surfaces, blockers, and the selected adapter allowed by the spec.
- [x] No repository implementation or product behavior is changed.

## Anchors

- `.oxlintrc.json:1-26` — current Oxlint configuration and plugin boundary.
- `package.json:4-16` — current frontend test and lint entry points.
- `package.json:50-60` — pinned Oxlint, TypeScript, Vitest, and Node versions.
- `../spec.md:77-87` — approved frontend source-policy contract and fallback.

## Investigation output

- **Question:** Can the pinned Oxlint plugin API implement the approved rule without losing required AST or comment information?
- **Evidence:** a temporary plugin/config/fixture outside the repository plus `artifacts/frontend-lint-adapter-feasibility.md`.
- **Decision owner:** the approved spec; use the thin Oxlint adapter when feasible and the standalone local Node check only when the probe demonstrates a blocker.
- **Unblocks:** ticket 03.

## Non-goals

- Do not implement production lint rules, alter `.oxlintrc.json`, add dependencies, or choose behavior outside the approved fallback.

## Focused verification

- `mise exec -- pnpm exec oxlint --version` — proves the investigation used the repository-pinned frontend linter.
- `mise exec -- pnpm exec oxlint --config /private/tmp/source-policy-oxlint.json /private/tmp/source-policy-fixture.tsx` — proves the disposable adapter loads, inspects TSX, reports its deliberate violation, and exits nonzero; record the expected nonzero result in the artifact.
