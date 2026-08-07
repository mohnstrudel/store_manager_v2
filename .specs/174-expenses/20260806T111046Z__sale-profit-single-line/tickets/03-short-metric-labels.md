# 03. Shorten the product economics labels

Spec: ../spec.md
Status: done
Blocked by: none

## What to build

Four labels on the Product show page's economics cards are longer than their dense metric columns warrant. Shorten them so the Product card and the Sale card speak one vocabulary:

| Was | Becomes |
|---|---|
| Merchandise cost | Merchandise |
| Direct expenses | Direct |
| Profit in hand | In hand |
| Unsold stock value | Unsold stock |

Each shortened label keeps its hover tip, its full hint text, and its glossary link, so the complete term stays one hover away. On the glossary page, each affected entry gains a line noting the shorter word the interface uses — the same treatment the `Debt` entry already gets.

`Revenue`, `OpEx, {n}%`, `Net Profit`, `Received`, `Outstanding`, and `Invested` are already short and do not change.

## Acceptance criteria

- [x] The Product profit card shows `Merchandise`, `Direct`, and `In hand` in place of the long labels.
- [x] The Product invested-total card shows `Unsold stock` in place of `Unsold stock value`.
- [x] Every renamed label still renders a tip trigger whose glossary link points at the same anchor as before (`merchandise`, `directExpenses`, `profitInHand`, `unsoldStockValue`).
- [x] The profit card still renders exactly 8 tip triggers.
- [x] The glossary entries for those four terms each show an interface-label line; their terms, definitions, and examples are unchanged.
- [x] `Direct expenses` still reads in full on the Purchase show, PurchaseItem show, SaleItem show, and Sale index pages.

## Anchors

- `app/frontend/pages/Products/Show/ProductEconomicsDashboard.tsx:104-141` — the `Merchandise cost`, `Direct expenses`, and `Profit in hand` labels inside `ProfitEquationCard`.
- `app/frontend/pages/Products/Show/ProductEconomicsDashboard.tsx:64-71` — the `Unsold stock value` label inside `InvestedTotalCard`.
- `app/frontend/pages/Products/Show/ProductEconomicsDashboard.test.tsx:14-56` — label assertions in `"renders the profit equation labels"` and `"hides the direct expenses term when none were recorded"`, plus the enumerating comment above the 8-tip count.
- `app/frontend/pages/Products/Show/ProductEconomicsDashboard.test.tsx:88-104` — `Profit in hand` assertions in the profit-figures and omission tests.
- `app/frontend/pages/Products/Show/ProductEconomicsDashboard.test.tsx:185-199` — `Unsold stock value` assertions in the invested-card tests.
- `app/frontend/pages/Glossary/Show.tsx:71-85` — the `merchandise` and `directExpenses` entries.
- `app/frontend/pages/Glossary/Show.tsx:119-134` — the `profitInHand` entry.
- `app/frontend/pages/Glossary/Show.tsx:143-148` — the `unsoldStockValue` entry.
- `app/frontend/pages/Glossary/Show.tsx:174-178` — the `debt` entry, the only existing `interfaceLabel` and the wording pattern to follow.
- `app/frontend/pages/Glossary/Show.tsx:12-15` — the `GlossaryEntry` type; `interfaceLabel` already exists, so no type change.

## Non-goals

- Do not rename `Direct expenses` at `Purchases/Show/Details.tsx:28`, `PurchaseItems/Show.tsx:83`, `SaleItems/Show.tsx:85`, or `Sales/Index/Table.tsx:101`. Those are prose-width detail labels with room to spare; the shortening is a property of the economics-snapshot cards only.
- Do not change any glossary term, definition, or example — only add `interfaceLabel`.
- Do not change hints in `financialMetricHints`; tip prose stays full-length.
- Do not change any glossary anchor id, value, or layout.
- Do not touch `ProfitabilitySummary` or `profitability.css`; ticket 02 owns those.

## Coordination notes

Fully independent — runs in parallel with tickets 01 and 02. Shares no file with either.

## Focused verification

- `mise exec -- pnpm exec vitest run app/frontend/pages/Products/Show/ProductEconomicsDashboard.test.tsx` — proves the renamed labels and the unchanged 8-tip count.
- `mise exec -- pnpm exec vitest run app/frontend/pages/Glossary` — proves the glossary entries still render with their new interface-label lines.
- `mise exec -- pnpm exec tsc --noEmit && mise exec -- pnpm exec oxfmt --check app/frontend` — types and formatting.
