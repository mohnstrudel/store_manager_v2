# Normalize imported sales to USD

## Problem

Purchases, supplier payments, expenses, and manually entered money are already stored in USD. Shopify and WooCommerce sale imports persist source amounts without converting them, so sale revenue and product or sale economics compare different currencies as if they were equal.

Current Shopify queries read `MoneyBag.shopMoney.amount` but omit `currencyCode` (`app/services/shopify/graphql/order_query.rb`, `app/models/sale/shopify/parser.rb`). Shopify defines `shopMoney` as the shop base currency, not always EUR. Current WooCommerce imports persist EUR order and line amounts directly (`app/jobs/woo/pull_sales_job.rb`), and product sale history presents follow-up payments as merchandise sales.

## Goal and approach

Persist all application money in USD. Convert external sale amounts at the Shopify, WooCommerce, and payment-plan import boundaries using the exchange rate for the external sale date. Keep purchases and manually entered values unchanged. Convert existing imported sales once, then make every later synchronization write USD directly.

Recommended data flow:

```text
External sale payload → identify source currency and sale date → resolve historical USD rate → convert → persist USD → allocate USD revenue to sale items
```

## Approved decisions

- **Approved — Internal currency:** Every persisted application monetary value is USD.
- **Approved — Existing USD data:** Purchases, supplier payments, expenses, and manually entered monetary data remain unchanged because they are already USD.
- **Approved — WooCommerce contract:** Incoming WooCommerce money is EUR and must be converted to USD. Core Orders API exposes order revenue, currency, status, `date_paid`, and refunds, but no amount received or balance due for partial payments. For a `partially-paid` order created by the store's deposits/partial-payments plugin, received revenue equals the plugin's own `deposit_amount` field when its `deposit_paid` flag is `yes` — a verified plugin ledger value, not a derived inference — and outstanding revenue stays `nil` because the plugin's post-deposit `second_payment_paid` flag does not reliably track ongoing installment collection. A `partially-paid` order without plugin deposit evidence keeps both received and outstanding `nil`; never derive either from `total`, `date_paid`, `needs_payment`, status, or an empty transaction ID.
- **Approved — Conversion date:** Imported sales use the exchange rate for the external sale date, not the synchronization date.
- **Approved — Historical conversion:** Existing imported sales must be converted to USD.
- **Approved — Future synchronization:** Every new or repeated external synchronization must convert source values before persistence and must not double-convert stored values.
- **Approved — Original values:** Do not retain original foreign amounts or currencies when conversion can operate reliably without them.
- **Approved — Rate source and persistence:** Cache official ECB daily reference rates and convert every source currency returned by Shopify or Seal to USD through the ECB cross-rate for the external sale date. USD passes through unchanged; non-business days use the latest prior published rates.
- **Approved — Missing rate history fallback:** When a currency has no ECB reference rate published on or before the external sale date (its ECB history starts after that date), fall back to the median of that currency's published rates within a three-month window centered on its nearest available rate, instead of raising. Ships as a follow-up ticket after the exchange-rate foundation lands.
- **Approved — Shopify currencies:** Request `shopMoney.currencyCode` beside every imported `shopMoney.amount` and use that currency directly in source-currency→USD conversion. Do not reject or skip synchronization based on currency.
- **Approved — Historical Shopify currency:** Existing Shopify amounts use the shop’s verified historical base currency because Shopify `shopMoney` is denominated in that base currency; do not re-fetch every historical order only to rediscover the same shop-level currency.
- **Approved — Migration safety:** The new `settlement_status` column carries conversion state: a sale is unconverted while `settlement_status` is `NULL`, and converted money, item reallocation, and settlement are written in one per-sale transaction. No global completion marker and no per-sale `converted` flag are added.
- **Approved — Schema cleanup:** Remove only `sale_payment_plans.currency` and `sale_payment_parts.currency`, and only after the historical conversion has read them; retain `status`, `next_due_at`, and `amount`.
- **Approved — Settlement model:** Persist one normalized `settlement_status` with `paid`, `not_fully_paid`, and `unknown`. `unknown` belongs to manual sales, which record no revenue amounts. Provider mappings are exhaustive: an unmapped provider status fails the manually triggered synchronization instead of persisting a placeholder. Use `Not fully paid` for both zero-paid and partly-paid positive sales. Deposits and payment plans are not settlement statuses.
- **Approved — Economic exclusion:** Cancelled, failed, voided, and fully refunded sales are excluded from positive economics by a scope over existing cancellation, status, and refund state, not by a settlement status value.
- **Approved — Payment-plan role:** Keep deposit/payment-plan relationships only where they group several external orders into one economic deal, prevent duplicate merchandise counts, or provide plan progress.
- **Approved — Product presentation:** Separate follow-up payment orders from merchandise sales and display the normalized settlement status explicitly.
- **Approved — Payment progress UI:** Every `not_fully_paid` sale shows a visual percentage bar whenever paid and total amounts are both verified exact. Scheduled plans may additionally show completed/total parts. Amount-only Shopify partials and Seal deposits use a continuous percentage bar, so a `$420` payment on a projected `$1,400` deal shows `30%`, never `1 of 1`. A Woo partial with a verified plugin deposit shows the deposit amount collected and the order total, with remaining stated as unavailable and no percentage bar, because only the deposit is a verified floor. A Woo partial without plugin deposit evidence shows an explicit unavailable message for both paid and remaining.
- **Approved — Sales index marker:** Show not-fully-paid progress before the sale details in the Sales index. Use concise structure-aware copy: `Deposit · 42% collected · Projected total $245`, `Payment 2 of 8 · 42% collected · Projected total $245`, or `Not fully paid · 42% collected · Total $245`. A Woo partial with a verified plugin deposit shows `Not fully paid · Deposit $196 collected · Total $1,145`, with no percentage. A Woo partial without plugin deposit evidence shows `Not fully paid · Payment amounts unavailable`.

### Behavior changes

| Path | Current behavior | Proposed behavior | Status |
|---|---|---|---|
| Shopify sale import | Persists `shopMoney.amount` without reading its currency. | Request `shopMoney.currencyCode` for every imported amount and convert that currency to USD using the sale-date ECB cross-rate. | Approved |
| WooCommerce sale import | Persists incoming EUR amounts directly. | Convert every imported WooCommerce monetary amount from EUR to USD before persistence. | Approved |
| Payment-plan import | Persists projections and part amounts in provider currency. | Convert monetary plan values to USD using the origin sale date before persistence. | Approved |
| Existing imported records | Shopify and WooCommerce values remain in source currency. | Convert external sales once; leave manual sales and all purchase-side data unchanged. | Approved |
| Revenue allocation | Allocates source-currency sale totals to items. | Convert order and line inputs first, then allocate already-converted USD totals once. | Approved |
| Product sale history | Presents follow-up payments as additional merchandise sales. | Keep payments inspectable but exclude them from merchandise counts and label them as payments. | Approved |
| Sale settlement | Fulfillment/workflow status, nullable amounts, provider-specific financial status, deposits, and plans overlap as payment classifications. | Importers persist one normalized settlement status; UI uses `Paid`, `Not fully paid`, or `Unknown`, and an exclusion scope keeps cancelled, voided, and fully refunded sales out of positive economics. | Approved |
| Payment progress | Plan schedules and amount progress use separate components, while generic partial orders have no unified summary. | One settlement summary always prefers a known paid/total percentage bar; schedules additionally show part counts; unknown Woo cash shows no fabricated progress. | Approved |

## Contracts

### Domain Contract

- **Owner and boundary:** Shopify and WooCommerce importers own source interpretation. A single exchange-rate domain capability owns ECB date lookup, source-currency→USD cross-rate conversion, decimal arithmetic, and rounding. `Sale` owns persisted USD order money and USD allocation to `SaleItem`. `SalePaymentPlan` owns USD contract projections.
- **State:** External payload amounts, currencies, and provider statuses are external state. `settlement_status` is the authoritative normalized application interpretation. Purchases and manual money are authoritative USD. Imported sale and payment-plan money becomes authoritative USD after conversion. Daily exchange rates are external reference data cached locally. Product and sale economics remain derived values.
- **Invariants:** Persisted money is USD. Every sale has one settlement status: `paid`, `not_fully_paid`, or `unknown`, and `unknown` means a manual sale that records no payment amounts. Cancelled, failed, voided, and fully refunded sales are excluded from positive economics by scope. Zero-paid and partly-paid positive sales are both `not_fully_paid`. WooCommerce input is EUR; Woo received revenue is the deposit plugin's verified `deposit_amount` when `deposit_paid` is `yes`, otherwise unknown, and Woo outstanding revenue is always unknown because post-deposit collection is not reliably tracked. Shopify input currency comes from `shopMoney.currencyCode`. Conversion uses the external sale date. A synchronization never converts a previously persisted value. Sale-item allocated revenue sums to its sale-level USD totals. A currency with no ECB rate published on or before the sale date falls back to the median of its nearest available rates within a three-month window.
- **Commands:** Each importer maps source evidence to `settlement_status` before persistence. Importers pass source amount, source currency, and external sale date to one conversion API before assigning money. `Sale#allocate_revenue_to_items!` runs only after conversion. Historical conversion and settlement backfill run through a one-time, resumable data command rather than model callbacks.
- **Inspection and recovery:** Raw provider status and monetary fields remain available to explain normalized settlement. A normalized daily-rate store exposes the exact ECB rates used for a date and source currency. Historical conversion requires a database backup because original foreign values are not retained, and unconverted sales stay identifiable by a null `settlement_status`.
- **Tests:** Cover settlement precedence and mappings for Shopify, WooCommerce, manual, cancelled, voided, fully refunded, zero-paid, partly-paid, and paid sales, and prove that an unmapped provider status raises instead of persisting a placeholder. Cover direct EUR→USD, USD passthrough, ECB cross-rates for observed Seal currencies, conversion dates, weekend or holiday fallback, rounding, Shopify `currencyCode`, Woo EUR imports, refunds, deposits, payment terms, repeat synchronization, historical conversion, allocation totals, unchanged manual USD, and unchanged purchase-side data.

### Frontend Contract

- **Owner and boundary:** Rails owns normalized settlement and sale/payment classification props. Sale and Product pages only format and present persisted USD and the normalized status.
- **State:** Backend props are authoritative. React derives labels and visual grouping only; it does not infer settlement from amounts, workflow status, plan kind, product names, or IDs.
- **Invariants:** Every displayed monetary value is USD. Positive sales display `Paid`, `Not fully paid`, or `Unknown`. Excluded sales do not contribute positive sales economics. A follow-up payment does not count as another unit sold.
- **Commands and transitions:** Not applicable — these surfaces display synchronized domain state; synchronization commands remain backend-owned.
- **Inspection and recovery:** Every not-fully-paid sale shows the strongest known progress. The Sales index places a concise progress marker before sale details. When paid and total USD are both verified exact, surfaces show a continuous percentage and paid/total/remaining amounts. Native Shopify terms and Seal installments may additionally show completed and expected parts. A Seal deposit with `$420` collected against projected `$1,400` shows `30%`, not `1 of 1`. A Woo partial order with a verified plugin deposit shows the deposit collected and the order total, with remaining stated as unavailable and no percentage bar; a Woo partial without plugin deposit evidence states that both paid and remaining amounts are unavailable. Users can still follow a plan’s origin and later charges when grouping is economically necessary.
- **Tests:** Request specs own normalized settlement, progress capabilities, and payment-classification props. Component tests cover paid, not fully paid, unknown, schedule progress, amount-only progress, Seal deposit progress, Woo verified-deposit progress, Woo fully unavailable amounts, follow-up grouping, plan progress, and that excluded sales contribute no positive economics.

## Boundaries and non-goals

- Do not convert purchases, supplier payments, expenses, or manually entered USD values.
- Do not build a general ledger or preserve parallel source-currency balances.
- Do not store original foreign amounts or currencies on sales or sale items.
- Do not perform currency conversion in `Sale` or `SaleItem` callbacks.
- Do not use synchronization time as the conversion date.
- Do not silently assume Shopify money is EUR; Shopify `shopMoney` uses the shop base currency.
- Do not fetch exchange rates independently from each parser or importer.
- Do not add permanent per-sale `converted` flags solely for the one-time migration.
- Do not use deposit, installment, or payment-plan kind as a settlement status.

## Testing decisions
- For every behavior-bearing slice with a fast seam, write one focused failing example first, run it to confirm the intended failure, implement the smallest change, and make it pass before adding the next case. Migrations, generated schema, and purely mechanical cleanup follow the behavior tests that require them.
- Write failing importer or parser examples before changing each synchronization path.
- Use independent literal rates and expected USD amounts; do not calculate expectations with production conversion code.
- Verify that exact cent-rounded allocations sum to converted sale totals.
- Verify a second synchronization produces the same USD values.
- Use model/domain specs for settlement, conversion, plan, role, allocation, and backfill invariants; parser/client specs with fixed fixtures and stubbed HTTP for external contracts; importer/job specs with real database transactions for write boundaries and idempotency; request specs for Rails-to-Inertia props; and Vitest component tests for visible labels, progress, grouping, and empty states.
- Do not contact live Shopify, WooCommerce, Seal, or ECB services in tests. Use independently fixed rates and payloads.
- Use a focused browser smoke check during implementation for the Sales index and Sale page composition; browser smoke complements but does not replace the TDD seams.
- Follow FactoryBot’s one-simple-factory-per-model rule. A default factory represents one realistic minimal record; source and state variants use explicit traits. For this work, replace ambiguous Sale/SaleItem setup with source-specific `:shopify`, `:woo`, and `:manual` traits and explicit settlement/plan setup where needed.
- Use `build` for validation and pure predicate examples, `create` only for database queries, constraints, importer transactions, request specs, and backfills, and `attributes_for` for importer/form payloads. Do not use factory callbacks to create unrelated provider records by default.
- Use fixed money, currency, date, provider ID, and order ID literals in financial examples. Avoid Faker and random IDs where the value participates in behavior or failure output.
- Stub only true boundaries: ECB/Shopify/Woo/Seal HTTP, time when relevant, and background enqueueing outside the job under test. Use real models, relations, transactions, and domain commands inside the boundary.
- Add FactoryBot lint coverage for the new factories and traits. Lint must prove each supported trait creates a valid isolated record.
- Keep one observable rule per example. Use `aggregate_failures` only for several outputs of the same worked scenario, not to combine unrelated behaviors.
- Verify the historical command cannot convert the same dataset twice.
- Verify the missing-history median fallback triggers only when no rate exists on or before the sale date, using independently computed median literals over a fixed three-month fixture window.
- Run focused Shopify parser/importer, Woo job, payment-plan, sale profitability, request, and React component tests during implementation.
- After the unticketed spec is complete, run the full repository gate from `AGENTS.md`: RSpec, Vitest, oxlint, oxfmt check, and TypeScript.

## Open proposals

None.
