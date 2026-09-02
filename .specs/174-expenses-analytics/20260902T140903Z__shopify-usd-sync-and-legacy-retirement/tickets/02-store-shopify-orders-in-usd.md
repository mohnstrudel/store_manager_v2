# 02. Store Shopify orders in USD

Spec: ../spec.md
Status: done
Blocked by: 01-cache-dated-eur-to-usd-rates

## What to build

Convert one raw Shopify order from EUR `shopMoney` to USD with one dated multiplier, then save every converted amount and the order's currency data in one atomic import.

## Acceptance criteria

- [x] Shared list and by-ID order fields request top-level `currencyCode`, `presentmentCurrencyCode`, and every required `shopMoney.amount`.
- [x] Remove nested `shopMoney.currencyCode` selections and tests that only supported field-by-field currency detection.
- [x] Add nullable `sales.shop_currency`, `presentment_currency`, `usd_conversion_rate decimal(18,10)`, and `exchange_rate_date` columns.
- [x] Database constraints allow the four currency fields to be all empty or all filled. Filled codes use three uppercase letters and a filled rate is positive.
- [x] Every successful Shopify import stores all four currency fields; existing Shopify rows may remain empty only until normal synchronization updates them.
- [x] One EUR-to-USD conversion covers totals, discounts, shipping, expected and received revenue, outstanding and refunded revenue, net payment, line-item prices and expected revenue, and Shopify `PaymentTerms` projections.
- [x] The stored `shop_currency` is EUR. A different `presentment_currency` is retained as metadata but does not change any amount.
- [x] Presentment amounts are not requested or stored.
- [x] The Shopify parser no longer selects a currency per monetary field or calls generic conversion methods for each amount. Remove its obsolete schedule-currency helpers.
- [x] Re-import converts raw Shopify values again and updates the same sale without double conversion.
- [x] A conversion or persistence failure leaves the existing sale aggregate unchanged.
- [x] Calculations and serializers continue reading the existing monetary columns, which now contain USD.
- [x] Add no branch, fallback, compatibility path, or test for missing or non-EUR `shopMoney`.
- [x] Seal payment plans, forecasts, parser, and storage remain unchanged.

## TDD cases

- `EUR shop money with CHF presentment` — parser/importer specs; write the failing example first and expect hand-calculated USD values plus EUR, CHF, multiplier, and effective date.
- `complete or empty currency data` — Sale database spec; expect both states to persist and partial data, invalid codes, or a non-positive rate to fail named constraints.
- `partial, refunded, discounted order` — parser spec; expect every order amount to use the same multiplier.
- `line items and Shopify payment terms` — parser/importer specs; expect the same multiplier on item and native schedule projections.
- `repeat raw import` — importer spec; expect one stable sale without double conversion.
- `rate or persistence failure` — importer spec; expect the previous sale, items, addresses, payment state, and currency data to remain unchanged.

## Worked example

For an order created on an ECB publication date with EUR-to-USD rate `1.1250`, EUR `100.00` becomes USD `112.50`. EUR `10.00` shipping becomes USD `11.25`. Both values use the same saved rate and effective date.

## Anchors

- `app/services/shopify/graphql/order_query.rb:15-178` — shared list and by-ID order fields.
- `app/models/sale/shopify/parser.rb:17-69` — order-level parsing.
- `app/models/sale/shopify/parser.rb:88-160` — Shopify payment-term parsing and obsolete currency selection.
- `app/models/sale/shopify/parser.rb:221-264` — line-item parsing and field-by-field conversion.
- `app/models/sale/shopify/importer.rb:19-46` — atomic sale snapshot write.
- `spec/services/shopify/graphql/order_query_spec.rb:5-112` — shared query and nested-currency tests.
- `spec/models/sale/shopify/parser_spec.rb:337-395` — existing order-money examples.

## Non-goals

No catalog-price conversion, presentment amounts, frontend conversion, Seal changes, WooCommerce persistence changes, or support for another Shopify shop currency.

## Focused verification

- `mise exec -- bin/rspec spec/models/sale_spec.rb spec/services/shopify/graphql/order_query_spec.rb spec/models/sale/shopify/parser_spec.rb spec/models/sale/shopify/importer_spec.rb spec/models/sale_payment_plan/seal/parser_spec.rb` — proves schema, query, one-rate conversion, atomic persistence, and unchanged Seal forecasts.
- `mise exec -- bundle exec rubocop app/models/sale.rb app/models/sale/shopify/parser.rb app/models/sale/shopify/importer.rb app/services/shopify/graphql/order_query.rb spec/models/sale_spec.rb spec/models/sale/shopify/parser_spec.rb spec/models/sale/shopify/importer_spec.rb spec/services/shopify/graphql/order_query_spec.rb db/migrate` — checks affected Ruby and migrations.
- `git diff --check` — checks patch whitespace.
