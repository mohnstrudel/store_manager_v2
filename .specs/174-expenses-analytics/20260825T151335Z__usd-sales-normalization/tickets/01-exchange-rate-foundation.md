# 01. Build the exchange-rate foundation

Spec: ../spec.md
Status: done
Blocked by: none

## What to build

Provide one reliable domain API that converts any source currency represented by ECB reference rates to USD using cached official daily rates for the external sale date. Exact-date rates win; weekends and ECB holidays use the latest earlier published rates; USD passes through unchanged.

## Acceptance criteria

- [x] Each persisted ECB rate identifies its date, quoted currency, value against EUR, and fetch time.
- [x] The database rejects duplicate date/currency rates, and one layer rejects non-positive rates.
- [x] EUR converts directly to USD with decimal arithmetic and a cent-rounded result.
- [x] CHF, GBP, CAD, AUD, and any other ECB-quoted source currency convert to USD through the same date’s EUR cross-rate.
- [x] USD converts to itself without an external lookup or rounding drift.
- [x] Once fetched, rates remain reusable without another ECB request.

## Anchors

- `app/services/seal/api/client.rb:124-135` — current `HTTParty` external-client error-handling convention.
- `app/models/sale/revenue_allocation.rb:59-65` — current cent rounding and remainder-preservation behavior for sale money.
- `db/schema.rb:13-16` — current PostgreSQL schema boundary where the new normalized table will appear through a migration.

## Worked example

For independently fixed ECB references on 2026-08-21 of `USD = 1.1250 per EUR` and `CHF = 0.9375 per EUR`:

- `100.00 EUR` becomes `112.50 USD`.
- `100.00 CHF` becomes `120.00 USD` because `100 / 0.9375 × 1.1250 = 120`.
- A sale dated Sunday 2026-08-23 uses the 2026-08-21 references when no later rate was published.
- `100.00 USD` remains `100.00 USD`.

## Failure and recovery

- Cached rates stay authoritative for repeated conversions.
- An unsuccessful or malformed ECB response persists no rates: the client raises before any insert, following the `Seal::Api::Client` convention.

## Non-goals

- Do not store original foreign sale amounts.
- Do not convert money from model callbacks.

## TDD sequence

1. Add one failing model or client example for the next observable rule and run only that example; confirm it fails because the rule is absent.
2. Implement the smallest production change that satisfies the example.
3. Run the focused example, then the complete focused command below.
4. Add the migration constraint checks before relying on application validation.

## Test cases

- Exact ECB business-day references convert `100.00 EUR` to `112.50 USD`.
- Same-date CHF/EUR and USD/EUR references convert `100.00 CHF` to the independent literal `120.00 USD`.
- GBP, CAD, and AUD use the same generic cross-rate path rather than currency-specific branches.
- Saturday, Sunday, and ECB-holiday dates use the latest earlier published references.
- USD passthrough returns the original decimal unchanged.
- Cent rounding uses an independent literal expectation at a half-cent boundary.
- Cached rates are reused without another HTTP request.
- Duplicate date/currency rows fail the database unique constraint.
- Non-positive rates are rejected.
- An unsuccessful or malformed ECB response persists no rate rows.

## Focused verification

- `mise exec -- bin/rspec spec/models/exchange_rate_spec.rb spec/services/ecb/exchange_rates_client_spec.rb --format progress --color` — proves normalized ECB persistence, generic cross-rate conversion, date fallback, caching, rounding, USD passthrough, and atomic response handling.
