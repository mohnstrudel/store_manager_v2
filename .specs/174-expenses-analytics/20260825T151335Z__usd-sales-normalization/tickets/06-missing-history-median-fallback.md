# 06. Fall back to a median rate when a currency has no ECB history

Spec: ../spec.md
Status: done
Blocked by: 01

## What to build

When `ExchangeRate.rate_on` finds no published rate for a currency on or before the requested date — the currency's ECB history starts after that date — return the median of that currency's rates published within three months of its nearest available rate, instead of raising.

## Acceptance criteria

- [x] A currency with zero published rates on or before the sale date resolves to the median of its rates within a three-month window centered on its nearest available (first) published date, rather than raising `ArgumentError`.
- [x] A currency with at least one published rate on or before the sale date is unaffected: exact-date and latest-earlier-date behavior from Ticket 01 remains unchanged.
- [x] A currency with absolutely no cached rate at any date (never published by ECB) still raises, since there is no nearest available rate to center a window on.
- [x] The median fallback reuses the same cached `ExchangeRate` rows Ticket 01 persists; it triggers no additional ECB request.

## Anchors

- `app/models/exchange_rate.rb:32-37` — current `rate_on` method that raises `ArgumentError` when no rate exists on or before the date; this ticket adds the fallback branch here.
- `app/models/exchange_rate.rb:39-45` — current `ensure_cached!` bulk persistence the fallback reuses without an extra ECB request.
- `spec/models/exchange_rate_spec.rb` — existing `.usd_amount` examples this ticket extends with a missing-history fixture.

## Worked example

ECB begins publishing a hypothetical currency XYZ on 2027-01-15. Its first six published rates (2027-01-15 through 2027-01-22, business days) are `1.10, 1.12, 1.08, 1.14, 1.09, 1.11` per EUR. A sale dated 2026-12-01 (before XYZ's ECB history starts) resolves XYZ's rate as the median of every XYZ rate published within three months of 2027-01-15 (its nearest available date), independently computed by hand from the fixed fixture rates, not derived from production code.

## Non-goals

- Do not change the exact-date or latest-earlier-date behavior for a currency that already has history at or before the sale date.
- Do not widen the window when data exists on both sides of the target date; the window centers on the nearest available rate only when no on-or-before rate exists at all.
- Do not backfill or re-run conversions already computed under Ticket 01's raise-on-missing behavior.

## TDD sequence

1. Add one failing example: a currency with only future-dated cached rows resolves to the hand-computed median instead of raising.
2. Implement the smallest branch in `rate_on` that computes the median over the three-month window.
3. Add a failing example proving a currency with zero cached rows at any date still raises.
4. Run the focused command below after each step.

## Test cases

- A currency with published rates only after the requested date resolves to the median of rates within three months of its earliest date, using an independent hand-computed median literal.
- A currency with an exact or earlier-dated rate still uses that rate directly; the median path never triggers.
- A currency with zero cached rows at any date still raises `ArgumentError`.
- The median fallback issues no additional ECB HTTP request.

## Focused verification

- `mise exec -- bin/rspec spec/models/exchange_rate_spec.rb --format progress --color` — proves the missing-history median fallback and its precedence against Ticket 01's existing exact/earlier-date behavior.
