# 08. Show unified sale payment progress

Spec: ../spec.md
Status: todo
Blocked by: 02, 03, 04

## What to build

Give every Sale page one settlement summary. Whenever paid and total amounts are known, show a continuous percentage bar with paid and remaining USD; scheduled plans may additionally show completed/total parts. Never invent parts or exact Woo partial-payment cash.

## Acceptance criteria

- [ ] Positive sales visibly show `Paid`, `Not fully paid`, or `Unknown` from the backend-owned normalized settlement status.
- [ ] Excluded sales do not appear as positive sales or positive economics.
- [ ] Every not-fully-paid sale with known paid and total amounts shows a continuous percentage bar plus paid, total, and remaining USD.
- [ ] Native Shopify payment terms and Seal installments additionally show completed and expected parts when the provider exposes a real schedule.
- [ ] A Shopify partial order without a schedule shows amount progress only.
- [ ] A Seal deposit with `$420` collected against projected `$1,400` shows `30%` and `$980 remaining`; it never renders `1 of 1`.
- [ ] A Woo `partially-paid` order with a verified plugin deposit shows `Not fully paid`, its USD order total, the USD deposit collected, and `Remaining amount unavailable from WooCommerce`, with no percentage fill. A Woo `partially-paid` order without plugin deposit evidence shows `Not fully paid`, its USD order total, and `Paid and remaining amounts unavailable from WooCommerce`, with no percentage fill.
- [ ] Every not-fully-paid Sales index row places a concise progress marker before the sale details.
- [ ] Deposit rows use `Deposit · 42% collected · Projected total $245`; scheduled follow-ups use `Payment 2 of 8 · 42% collected · Projected total $245`; amount-only sales use `Not fully paid · 42% collected · Total $245`.
- [ ] Woo partial index rows with a verified plugin deposit use `Not fully paid · Deposit $196 collected · Total $1,145`, never a percentage. Woo partial index rows without plugin deposit evidence use `Not fully paid · Payment amounts unavailable` and never show a fabricated percentage.
- [ ] Payment progress updates after the existing manual Shopify or Woo synchronization; no webhook is introduced.
- [ ] Rails owns the normalized settlement status and every progress capability prop.

## Anchors

- `app/helpers/sale_helper.rb:14-24` — existing sale amount-progress props.
- `app/helpers/sale_helper.rb:136-180` — existing plan context and progress props.
- `app/frontend/components/PaymentProgressBar.tsx:5-60` — existing amount-progress presentation.
- `app/frontend/components/PlanProgressBar.tsx:3-41` — existing scheduled-part presentation.
- `app/frontend/pages/Sales/Show/Details.tsx:14-51` — Sale page details and plan-progress composition.
- `app/frontend/pages/Sales/Index/Table.tsx:38-83` — Sales index status context.
- `app/frontend/pages/Customers/components/Sales.tsx:36-70` — Customer sale status context.

## UI states

- Native terms or installments: `Not fully paid · 50% · 2 of 4 payments completed · Paid $500 of $1,000 · $500 remaining`.
- Amount-only Shopify partial: `Not fully paid · 30% · Paid $300 of $1,000 · $700 remaining`.
- Seal deposit without a future schedule: `Not fully paid · 30% · Paid $420 of projected $1,400 · $980 remaining`.
- Sales index deposit marker: `Deposit · 42% collected · Projected total $245`.
- Sales index scheduled marker: `Payment 2 of 8 · 42% collected · Projected total $245`.
- Sales index amount-only marker: `Not fully paid · 42% collected · Total $245`.
- Woo partial with a verified plugin deposit: `Not fully paid · Deposit $196 collected of total $1,145 · Remaining amount unavailable`, no percentage fill.
- Sales index Woo deposit-known marker: `Not fully paid · Deposit $196 collected · Total $1,145`, no percentage.
- Woo partial without plugin deposit evidence: `Not fully paid · Paid and remaining amounts unavailable from WooCommerce`, no percentage fill.
- Sales index Woo unavailable marker: `Not fully paid · Payment amounts unavailable`.
- Unknown: show `Payment status unknown` without zero amounts or invented progress.

## Non-goals

- Do not invent a payment count when the provider exposes only amounts; use the amount percentage bar instead.
- Do not make deposits, installments, or payment terms into settlement statuses.
- Do not change payment-plan reconciliation or currency conversion.

## TDD sequence

1. Start with failing Rails helper/request examples for one normalized settlement and progress capability; implement props before UI.
2. Add one failing component example per UI state and assert user-visible text and progress, not component internals.
3. Reuse real `PaymentProgressBar` and `PlanProgressBar` where their coordination is under test; do not mock the behavior owner.
4. Run backend contract tests, then component tests and TypeScript after each state is green.

## Test cases

- `paid`, `not_fully_paid`, and `unknown` render their exact labels; sales inside the exclusion scope render no positive status or economics.
- Known `$420` of `$1,400` renders a 30% bar, paid amount, total, and `$980` remaining.
- Zero paid of a known total renders 0% and `Not fully paid`, not `Unknown`.
- Fully paid renders 100%/`Paid` without a remaining-debt claim.
- Native terms and Seal installments show actual completed/expected parts plus independently calculated amount percentage.
- Unequal schedules can show `2 of 4` and a percentage other than 50%.
- Seal deposit renders amount percentage and never `1 of 1`.
- Shopify amount-only partial renders percentage and amounts without a part count.
- Woo partial without plugin deposit evidence renders order total and the exact unavailable message with no percentage fill.
- Woo partial with a verified plugin deposit renders order total, converted deposit received, and a remaining-unavailable message with no percentage fill; it never sums deposit against total to imply a known outstanding figure.
- Sales index renders the approved deposit, scheduled, amount-only, and Woo marker copy before sale details.
- Customer and Sale pages consume the same normalized status and do not create alternate wording.
- Unknown amounts never render zero, debt, percentage, or a fabricated part count.
- Follow-up payment context remains visible without turning plan kind into settlement status.

## Focused verification

- `mise exec -- bin/rspec spec/helpers/sale_helper_spec.rb spec/requests/sales_spec.rb --format progress --color` — proves normalized settlement and capability-based progress props.
- `mise exec -- pnpm exec vitest run app/frontend/components/PaymentProgressBar.test.tsx app/frontend/components/PlanProgressBar.test.tsx app/frontend/pages/Sales/Show.test.tsx app/frontend/pages/Sales/Show/Details.test.tsx app/frontend/pages/Sales/Index.test.tsx app/frontend/pages/Customers/Show.test.tsx` — proves every supported progress state and source limitation.
- `mise exec -- pnpm exec tsc --noEmit` — proves the unified progress contract is type-safe.
