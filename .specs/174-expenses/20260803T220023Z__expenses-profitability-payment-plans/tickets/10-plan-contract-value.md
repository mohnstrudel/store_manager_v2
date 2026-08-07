# 10. Give every payment plan a contract value

Spec: ../spec.md
Status: done
Blocked by: none

## What to build

A Shopify order carries its whole payment schedule, but the importer keeps only the individual
parts, so a Shopify plan never records what the deal is worth in total. Everything needed is
already fetched — record the contract total, and record the deposit share when the first charge
is deliberately smaller than the rest.

The SEAL importer computes the same kind of figure with a formula copy-pasted from a model
method that has no production caller. Route it through the shared method so one formula serves
both providers.

## Acceptance criteria

- [x] A Shopify plan whose schedule amounts are equal records a contract total and leaves the deposit share unset — equal instalments are not a deposit.
- [x] A Shopify plan whose first schedule is smaller than the rest records both the contract total and the deposit share.
- [x] A plan with a single schedule records no deposit share; one charge is the whole deal, not a fraction of it.
- [x] SEAL plans record exactly the values they recorded before, computed by the shared method rather than a local copy.
- [x] The shared method has at least one caller outside the test suite.

## Anchors

- `app/models/sale/shopify/parser.rb:83-114` — `#parse_payment_plan`. Today its `attributes:` hash
  has no `projected_total` and no `deposit_percent` key at all. `#payment_schedules` (`:116-118`)
  already returns the nodes; each carries `totalBalance: {amount:, currencyCode:}`.
- `app/models/sale_payment_plan.rb:93-98` — `.projected_deposit_total(deposit_merchandise_amount:,
  deposit_percent:, shipping_amount:)`. Currently referenced only by
  `spec/models/sale_payment_plan_spec.rb:161`.
- `app/models/sale_payment_plan/seal/parser.rb:64-71` — `#projected_total`, which duplicates that
  formula inline as `(merchandise_total / (payment_percent / 100)) + shipping_amount`. Its
  `#unambiguous_pricing?` guard (`:73-79`) must keep working unchanged.
- `db/schema.rb:358-376` — both columns already exist: `projected_total` `decimal(12,2)`,
  `deposit_percent` `decimal(5,2)`. No migration is needed.

## Worked examples for the tests

Derive the expected values from these by hand; do not read them off the implementation.

| Case | Schedules | `projected_total` | `deposit_percent` |
|---|---|---|---|
| Equal instalments | 255, 255, 255, 255 | 1020.00 | nil |
| Deposit then instalments | 306, 238, 238, 238 | 1020.00 | 30.00 |
| Single schedule | 1020 | 1020.00 | nil |

SEAL regression: `projected_deposit_total(deposit_merchandise_amount: 300, deposit_percent: 30,
shipping_amount: 20)` = `300 / 0.30 + 20` = **1020.00**, matching the inline formula's result for
the same subscription.

## Non-goals

- Do not change `expected_parts`, `kind`, `status`, part reconciliation, or the currency fields.
- Do not backfill plans imported before this ticket — they gain the total on their next import.
- Do not touch `Shopify::Api::Client` or the GraphQL query; `totalBalance` is already selected.

## Verification

All gates from `AGENTS.md`, each through `mise exec --`:

```bash
mise exec -- bin/rspec --format progress --color
```

```bash
mise exec -- pnpm exec vitest run
```

```bash
mise exec -- pnpm exec tsc --noEmit && mise exec -- pnpm exec oxlint app/frontend && mise exec -- pnpm exec oxfmt --check app/frontend
```
