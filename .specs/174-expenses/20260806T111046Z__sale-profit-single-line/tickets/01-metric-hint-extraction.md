# 01. Extract the metric hover tip into its own component

Spec: ../spec.md
Status: done
Blocked by: none

## What to build

A metric's hover tip — the `*` trigger, its plain-language hint, and its glossary link — becomes usable on its own, without a label in front of it. Today that tip only exists welded to a label inside `MetricLabel`, so a bare figure cannot carry one.

Nothing changes on screen. Every existing label keeps its tip, its hint text, and a glossary link pointing at the same anchor.

## Acceptance criteria

- [x] A new `MetricHint` renders the tip trigger, hint text, and glossary link given an `anchor` and a `hint`, with no label text of its own.
- [x] `MetricLabel` keeps its exact props (`anchor`, `children`, `hint`) and produces the same DOM as before, now by composing `MetricHint`.
- [x] `MetricLabel.test.tsx` passes with no edits to it.
- [x] The Product economics dashboard still shows exactly 8 tip triggers on its profit card, unchanged.

## Anchors

- `app/frontend/components/profitability/MetricLabel.tsx:12-26` — the `MetricLabel` component; lines 16-24 are the tip body to extract (the `aria-hidden` wrapper around `TipMark`, the `tip_mark__hint` span, and the `tip_mark__glossary_link` `Link`).
- `app/frontend/components/profitability/MetricLabel.test.tsx:1-52` — the three tests that pin label rendering, the glossary href, and the `More information` trigger. This file is the guard: it must pass untouched.
- `app/frontend/components/TipMark.tsx:22-72` — `TipMark` owns open state and floating placement. Do not change it.

## Non-goals

- Do not change any label text, hint text, or glossary anchor.
- Do not touch `ProfitabilitySummary`, `ProductEconomicsDashboard`, or `financialMetricHints`.
- Do not add props to `MetricLabel` or change its call sites.
- Do not leave a re-export or pass-through shim; `MetricLabel` composes `MetricHint` directly.

## Focused verification

- `mise exec -- pnpm exec vitest run app/frontend/components/profitability` — proves `MetricLabel` renders identically after the extraction.
- `mise exec -- pnpm exec vitest run app/frontend/pages/Products/Show/ProductEconomicsDashboard.test.tsx` — the `getAllByLabelText("More information")` count at `ProductEconomicsDashboard.test.tsx:53` proves no tip was gained or lost across a real consumer.
- `mise exec -- pnpm exec tsc --noEmit` — proves the new module's types line up.
