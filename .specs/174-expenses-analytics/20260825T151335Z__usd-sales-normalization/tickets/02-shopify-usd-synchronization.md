# 02. Normalize Shopify sales to USD

Spec: ../spec.md
Status: done
Blocked by: 01

## What to build

Make every manually triggered Shopify synchronization request `shopMoney.currencyCode`, convert each source amount to USD using the order creation date, persist one normalized settlement status, and allocate converted revenue exactly once. This ticket owns the `settlement_status` column, its enum, the shared precedence mapper, and the economic-exclusion scope that Tickets 03, 05, and 08 consume.

## Acceptance criteria

- [x] The Shopify order query requests `currencyCode` beside every imported `shopMoney.amount`.
- [x] EUR order and line money converts to USD.
- [x] USD order and line money persists unchanged.
- [x] Other Shopify `shopMoney` currencies convert through the same generic source-currency→USD path.
- [x] Conversion uses `shopify_created_at`, never pull time.
- [x] Item `price` and `expected_revenue` convert before persistence; received, outstanding, and refunded item revenue derives once from converted order totals.
- [x] Re-importing the same Shopify payload produces the same USD values without double conversion.
- [x] The `settlement_status` column, enum, shared precedence mapper, and economic-exclusion scope land here as the single owner for Woo, the backfill, and the UI.
- [x] The importer persists `paid` or `not_fully_paid` from authoritative Shopify financial, balance, and refund evidence, and raises on an unmapped financial status instead of persisting a placeholder.
- [x] Native payment schedules and amount-only partial orders persist the paid, total, and part-count values Ticket 08 formats; this ticket proves persistence, not presentation.

## Anchors

- `app/services/shopify/graphql/order_query.rb:31-69` — currently selects amounts without order money currency codes.
- `app/models/sale/shopify/parser.rb:52-64` — currently extracts unconverted sale and payment amounts.
- `app/models/sale/shopify/parser.rb:248-250` — currently discards `shopMoney.currencyCode`.
- `app/models/sale/shopify/importer.rb:19-29` — transaction and post-item revenue allocation order.
- `app/models/sale/shopify/importer.rb:43-47` — sale attribute persistence boundary.
- `spec/models/sale/shopify/parser_spec.rb:340-389` — payment, refund, and fallback parser seam.

## Contract example

A Shopify order created on 2026-08-21 carries `shopMoney = 100.00 EUR`. With the independently fixed rate `1.1250`, it persists `112.50 USD`. The same payload synchronized again still persists `112.50`, not `126.56`.

## Source-currency contract

- Shopify `shopMoney` supplies the source currency used by conversion.
- Synchronization does not reject or skip an order because its `currencyCode` differs from EUR or USD.

## Non-goals

- Do not use `presentmentMoney` or customer-selected currency.
- Do not assume Shopify is always EUR.
- Do not retain Shopify source amounts or currencies after conversion.
- Do not change WooCommerce or historical records in this ticket.

## Coordination notes

- Ticket 04 also touches Shopify payment-plan parsing and must start after this ticket.
- Ticket 03 consumes the `settlement_status` schema, mapper, and exclusion scope introduced here, so it starts after this ticket.

## TDD sequence

1. Start at the query/parser seam with a failing example proving `currencyCode` is currently absent.
2. Add source-currency propagation, generic conversion, and settlement mapping in separate red-green steps.
3. Add multi-currency and repeat-import examples before broadening the implementation.
4. Run the complete focused command only after each narrow example passes.

## Test cases

- GraphQL selects `currencyCode` beside every imported `shopMoney.amount`, including order, payment, refund, shipping, discount, and line totals.
- EUR order and line values convert at the `shopify_created_at` rate with independent literal USD expectations.
- USD order and line values remain unchanged; CHF, GBP, CAD, and AUD examples use the generic cross-rate converter.
- `PAID` with zero outstanding persists `settlement_status = paid`.
- `PENDING`, `PARTIALLY_PAID`, or positive outstanding persists `not_fully_paid`.
- Cancelled, `VOIDED`, and fully refunded orders keep their settlement mapping and fall inside the economic-exclusion scope; an unmapped financial status raises.
- Amount-only partial orders expose paid, total, remaining, and percentage capability without a part count.
- Native schedules expose real completed/expected part counts plus amount progress.
- Converted sale-level received, outstanding, and refunded totals allocate to items exactly once and sum back to the sale values.
- Importing the same source payload twice produces identical USD and settlement values.

## Focused verification

- `mise exec -- bin/rspec spec/services/shopify/graphql/order_query_spec.rb spec/models/sale/shopify/parser_spec.rb spec/models/sale/shopify/importer_spec.rb spec/jobs/shopify/pull_sale_job_spec.rb spec/jobs/shopify/pull_sales_job_spec.rb --format progress --color` — proves the query, currency propagation, generic conversion, allocation, settlement, and repeated-synchronization contracts.
