# 13. Show a payment's place in the plan instead of its own progress

Spec: ../spec.md
Status: done
Blocked by: 12

## What to build

A single instalment charge is either paid or it isn't, so its progress bar sits at 100 % almost
always and tells the reader nothing. The useful question on a payment page is not "is this charge
paid" but "how much of the deal does this charge cover, and how far along are we".

Replace the bar on payment pages with one that spans the whole plan, divided into a segment per
charge, with the segments already collected filled in and this charge's own segment picked out.

The order-level bar stays exactly as it is everywhere else — it answers a different question and
answers it well.

## Acceptance criteria

- [x] A payment page shows a bar covering the whole plan, divided into one segment per expected charge.
- [x] The number of filled segments equals the number of charges collected so far.
- [x] The segment for the charge being viewed is distinguishable from the others by something other than colour alone.
- [x] A caption states this charge's position in the plan and how much of the contract value has been collected.
- [x] The order-level progress bar is unchanged and still renders on originating orders, the sales list, and the customer's sales table.
- [x] A plan whose contract value is unknown still renders the segments and position, omitting only the money part of the caption.

## Anchors

- `app/frontend/components/PaymentProgressBar.tsx` — the existing bar. Read it for the styling
  idiom (`progress_container`, `progress_amount`) and the way it names missing amounts rather than
  interpolating blanks (`paidLabel` / `debtLabel`, `:55-65`). **Do not modify this file.**
- `app/frontend/pages/Sales/Show/PaymentSummary.tsx:25-27` — where `PaymentProgressBar` is rendered
  on the sale page; this is the swap site. `PaymentPlanDetails` (`:48-68`) already receives the
  plan and renders `Projected total` / `Projected remainder` / `Next payment`.
- `app/models/sale_payment_plan.rb` — `#collected_parts` (`:111-115`), `#part_number_for(sale)`
  (`:124-126`), `#projected_remainder` (`:117-122`), and the `expected_parts` column supply every
  figure the bar needs. `app/helpers/sale_helper.rb:182-201` (`#sale_payment_plan_props`) already
  serializes `expected_parts`, `collected_parts`, `sale_part_number`, `projected_total`,
  `projected_remainder`.
- `app/frontend/types/payment.ts` — `SalePaymentPlanRecord`.
- `app/frontend/styles/application/` — segment styling belongs in a named class here, not as
  utility classes in JSX, matching the style decision recorded in the spec.

## Worked example for the tests

A four-part plan of 255 per charge, contract value 1 020, with two charges collected, viewed from
the second charge:

- 4 segments, 2 filled, segment 2 marked as current.
- Caption: `Payment 2 of 4 · 510 of 1 020 collected`.

## Non-goals

- Do not change `PaymentProgressBar`, its props, or any of its current call sites.
- Do not add the segmented bar to the sales list or the customer table — this ticket is the payment
  page only.
- Do not compute collected counts in React; they come from the server.

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
