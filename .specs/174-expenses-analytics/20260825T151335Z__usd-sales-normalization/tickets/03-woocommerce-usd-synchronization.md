# 03. Normalize WooCommerce sales to USD

Spec: ../spec.md
Status: todo
Blocked by: 01, 02

## What to build

Treat every incoming WooCommerce sale amount as EUR, convert the complete order to USD using `woo_created_at`, and persist one normalized settlement status before saving or allocating item revenue.

## Acceptance criteria

- [ ] Order total, discount, shipping, expected revenue, refunds, received revenue, and outstanding revenue convert from EUR to USD.
- [ ] Line price and expected revenue convert from EUR to USD before persistence.
- [ ] A `partially-paid` order without plugin deposit evidence keeps received and outstanding `nil`; conversion does not turn them into zero. A `partially-paid` order with a verified plugin deposit (`_awcdp_deposits_deposit_paid = "yes"`) persists received revenue as the converted `_awcdp_deposits_deposit_amount`; outstanding stays `nil` regardless.
- [ ] Conversion uses `woo_created_at`, never pull time or local record creation time.
- [ ] Sale-item allocated revenue derives once from converted USD order totals.
- [ ] Woo’s explicit `currency` field is the conversion input rather than a hardcoded EUR literal.
- [ ] A paid non-partial order persists `paid`; an unpaid or `partially-paid` order persists `not_fully_paid`; cancelled, failed, and fully refunded orders keep their mapping and fall inside Ticket 02’s economic-exclusion scope; an unmapped Woo status raises.
- [ ] A Woo `partially-paid` order exposes its USD order total and, when a verified plugin deposit exists, the converted deposit amount received; otherwise it exposes an explicit unavailable amount capability for the unified progress summary. Outstanding is always the unavailable capability for Woo partials.

## Woo cash contract

- Core Woo Orders API provides order totals, currency, status, `date_paid`, and refunds, but no payment ledger, amount received, or balance due for a partial payment.
- For a non-partial order, preserve the existing binary interpretation: `date_paid` means received revenue equals the order total and outstanding revenue is zero; without `date_paid`, received revenue is zero and outstanding revenue equals the order total.
- For `partially-paid`, read the store's deposits/partial-payments plugin order meta (`_awcdp_deposits_deposit_amount`, `_awcdp_deposits_deposit_paid`) directly — this is a verified plugin ledger field, not a derived inference. When `_awcdp_deposits_deposit_paid = "yes"`, received revenue equals the converted `_awcdp_deposits_deposit_amount`. Outstanding revenue stays `nil` in every `partially-paid` case: the plugin's `_awcdp_deposits_second_payment_paid` flag is a single yes/no over the entire post-deposit remainder and does not reliably reflect ongoing installment collection, so it must never be read as outstanding or as "fully paid." When plugin deposit meta is absent, both received and outstanding stay `nil`. Never derive either amount from `total`, `date_paid`, `needs_payment`, status, or an empty transaction ID.
- Refunds remain separately known and convert from EUR to USD.

## Anchors

- `app/jobs/woo/pull_sales_job.rb:15-24` — Woo fetch, parse, and create sequence.
- `app/jobs/woo/pull_sales_job.rb:27-70` — transaction, line persistence, and revenue allocation boundary.
- `app/jobs/woo/pull_sales_job.rb:89-130` — unconverted order and line parsing.
- `app/jobs/woo/pull_sales_job.rb:132-153` — refund and payment-split derivation, including unknown partial payments; extend here to read `_awcdp_deposits_deposit_amount`/`_awcdp_deposits_deposit_paid` order meta.
- `spec/jobs/woo/pull_sales_job_spec.rb` — focused Woo parser and persistence seam.

## Worked example

For a Woo order created on 2026-08-21 and an independently fixed rate `1 EUR = 1.1250 USD`:

- `80.00 EUR` total persists as `90.00 USD`.
- `10.00 EUR` refund persists as `11.25 USD`.
- A `partially-paid` order without plugin deposit evidence keeps received/outstanding `nil`.
- A `partially-paid` order with a verified plugin deposit of `50.00 EUR` (`_awcdp_deposits_deposit_paid = "yes"`) persists received revenue as `56.25 USD`; outstanding stays `nil`.

## Failure and recovery

- Rate resolution happens before the transaction commits order or item money.

## Non-goals

- Do not preserve incoming EUR amounts.
- Do not infer paid amounts for Woo partial-payment orders from `total`, `date_paid`, `needs_payment`, status, or an empty transaction ID; only read the deposit plugin's own `deposit_amount`/`deposit_paid` fields directly.
- Do not read `_awcdp_deposits_second_payment` or `_awcdp_deposits_second_payment_paid` as outstanding revenue or as a fully-paid signal.
- Do not change Shopify, payment plans, or historical records in this ticket.

## Coordination notes

- This ticket starts after Ticket 02, which owns the `settlement_status` schema, mapper, and exclusion scope.

## TDD sequence

1. Add a failing `Woo::PullSalesJob` example around one source status and literal rate; confirm the current importer persists EUR.
2. Implement conversion and settlement mapping one source state at a time.
3. Add the partial-payment unknown-cash example before touching its current guard.
4. Run the complete Woo job spec after each red-green slice.

## Test cases

- EUR total, discount, shipping, refund, line price, and line expected revenue convert at `woo_created_at`.
- Paid non-partial order persists `paid`, received equal to converted total, and zero outstanding.
- Unpaid non-partial order persists `not_fully_paid`, zero received, and outstanding equal to converted total.
- `partially-paid` without plugin deposit evidence persists `not_fully_paid` while received and outstanding stay `nil`.
- `partially-paid` with a verified plugin deposit persists `not_fully_paid`, received equal to the converted deposit amount, and outstanding `nil`.
- Cancelled, failed, and fully refunded Woo orders keep their mapping and fall inside the exclusion scope; an unmapped status raises.
- Woo partial progress without plugin deposit evidence exposes converted order total and `amounts unavailable`, with no percentage.
- Woo partial progress with a verified plugin deposit exposes converted order total, converted deposit received, and an unavailable remaining amount, with no percentage.
- The order’s `currency` field reaches the generic converter.
- Historical rate lookup uses the order date and cached ECB references.
- Refund conversion remains separate from received revenue and uses a literal expected net result.
- Item allocations sum to converted order totals after import.

## Focused verification

- `mise exec -- bin/rspec spec/jobs/woo/pull_sales_job_spec.rb --format progress --color` — proves complete source-currency→USD conversion, unknown partial-payment preservation, settlement mapping, and allocation order.
