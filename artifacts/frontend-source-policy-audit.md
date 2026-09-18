# Frontend source-policy audit (ticket 03)

## Commands

```
mise exec -- pnpm exec vitest run tools/source-policy/frontend
mise exec -- pnpm lint:source-policy
mise exec -- node tools/source-policy/frontend/cli.js --runtime-files
mise exec -- node tools/source-policy/frontend/cli.js --test-files
```

Run against the repository tree before any cleanup ticket (09-10) has touched a file.
`pnpm lint` and `.oxlintrc.json` are untouched; `pnpm lint:source-policy` is a separate
command that loads the thin Oxlint JS plugin (`tools/source-policy/frontend/oxlint-plugin.js`)
through its own isolated config (`tools/source-policy/frontend/oxlint.config.json`, all
built-in categories off) for JS/JSX/TS/TSX, plus a standalone Node CSS comment scanner
(`tools/source-policy/frontend/css-comments.js`) for `.css` files, since Oxlint has no CSS
rule API.

## Result

`pnpm lint:source-policy` (full audit, no flag): exit status 1 (nonzero).

| Selector | `ordering` | `no-prose-comments` (JS/TS/TSX) | CSS comments | Total |
| --- | --- | --- | --- | --- |
| Full audit (no flag) | 77 | 171 | 27 | 275 |
| `--runtime-files` (ticket 09) | 72 | 79 | 27 | 178 |
| `--test-files` (ticket 10) | 5 | 92 | 0 (excluded) | 97 |

**Correction (during ticket 09/10 cleanup):** `isTestPath` in `tools/source-policy/frontend/cli.js`
originally only matched the top-level `app/frontend/test/` prefix and `*.test.ts(x)`
filenames, so it missed page-local `app/frontend/pages/*/test/factories.ts` files (16 of
them), which the Frontend Contract's "test factories" category and ticket 10's ownership
both cover. Fixed to match any `test/` path segment. The full-audit total (275) and the
`--runtime-files`/`--test-files` split point are unaffected in aggregate, but roughly a
dozen offenses in those page-local factory files move from the `--runtime-files` column to
the `--test-files` column relative to the numbers above, which predate the fix.

`--runtime-files` and `--test-files` partition the JS/JSX/TS/TSX offenses exactly
(72+5=77, 79+92=171); `--test-files` never scans CSS since test files have none.

## Representative false-positive review

- `app/frontend/components/ImageGallery.tsx:46` — `ImageGallery` (the file's sole
  root/entry component, called externally, not from within the file) is required to
  precede `useGallery` (declared above it at line 40) because `useGallery` is only
  reached, transitively, through `ImageGallery`'s own JSX subtree (`SingleGallery` /
  `CarouselGallery` → … → `useGallery`). This is the same "shared helper hoisted above
  its transitive caller-root" shape as the spec's motivating `Sale#payment_plans_for_display`
  example — a real violation, not a false positive.
- `app/frontend/pages/Products/components/Form.tsx` (4 offenses) — each flagged
  declaration (`newVariant`, `ProductForm`, `TiptapSkeleton`, `useProductFormSections`) is
  declared after a sibling that is its only in-file caller; hand-tracing each call site
  confirms real depth-first violations.
- `app/frontend/test/mocks/resourceForm.tsx:1-22` — a 22-line hand-written usage-instructions
  comment block above the mock; each `//` line is reported individually because each is its
  own AST comment node. Not a false positive: it is prose, and per-line reporting is
  expected, if verbose, behavior for a multi-line `//` block.
- `app/frontend/components/profitability/metricLabels.ts:1-5` — a hand-written explanatory
  paragraph above an exported constant; genuine prose.
- `app/frontend/styles/application/base.css:2,25,49` — ordinary CSS section-header
  comments (`/* Global */`, `/* Typography */`, `/* Disclosure widgets … */`); manually
  verified the scanner's reported line/column against the file and confirmed exact
  alignment, and that it correctly skips a `/* ... */`-shaped sequence inside a CSS string
  literal (unit-tested; no live instance of that pattern was found in this codebase).
- `app/frontend/pages/Products/Show/ProductEconomicsDashboard.test.tsx:157` — `group` is
  declared after `termOrFail`, its only caller in the file; a genuine ordering violation in
  a test helper, in ticket 10's scope.

No false positives found. No ignored-dispatch site (imports, other-object or computed
calls, value-only callback references, object-literal methods) was observed creating a
spurious edge in the sampled files, and no approved exact directive
(`eslint-disable-next-line`, `oxlint-disable-next-line`, `@ts-expect-error`, etc.) was seen
incorrectly flagged.

## Adapter and scope

Per `artifacts/frontend-lint-adapter-feasibility.md` (ticket 01), the Oxlint JS-plugin
adapter is used for all JS/JSX/TS/TSX checking; no parser dependency was added. The CSS
scanner is a small standalone Node module with no dependency, matching the approved
fallback for CSS (out of Oxlint's rule-API scope regardless of plugin maturity).

`tools/source-policy/frontend/**/*.test.js` is now part of the Vitest `include` glob
(`vitest.config.ts`) so `pnpm exec vitest run` / `bin/test` exercise these tests
automatically; `tools/` is outside `tsconfig.json`'s `include` and outside `pnpm lint`'s
`app/frontend` scope, so it is not separately type-checked or linted by the ordinary
frontend gates.

## Scope not audited here

No application or test source was reordered and no legacy prose comment was removed by
this ticket. Cleanup happens in tickets 09-10; ticket 11 wires `pnpm lint:source-policy`
into the ordinary `pnpm lint` gate once both scopes are clean.
