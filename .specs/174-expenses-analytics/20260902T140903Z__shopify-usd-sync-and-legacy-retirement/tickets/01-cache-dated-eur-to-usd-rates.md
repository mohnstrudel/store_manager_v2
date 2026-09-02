# 01. Cache dated EUR-to-USD rates

Spec: ../spec.md
Status: done
Blocked by: none

## What to build

Make `ExchangeRate` return one dated EUR-to-USD conversion and keep the ECB cache fresh enough for bulk Shopify synchronization without repeated network requests.

This is shared rate infrastructure. It must work before a Shopify sale can save auditable conversion data.

## Acceptance criteria

- [x] A conversion returns the requested order date, effective ECB publication date, positive EUR-to-USD multiplier, and cent-rounded USD amounts.
- [x] A weekend or ECB holiday uses the latest earlier publication date.
- [x] Shopify conversion does not use the existing median fallback, a later rate, or a current-rate substitute.
- [x] An empty cache makes one full-history request and persists the returned rows.
- [x] A cache no older than 24 hours makes no request; an older cache makes one recent-feed request.
- [x] A successful refresh records freshness even when the recent feed contains no new publication date, so later orders do not repeat the request.
- [x] Existing historical rates do not change during refresh.
- [x] After the cache is ready, any number of order conversions use stored rows and make no further ECB requests.
- [x] A failed required fetch or missing rate raises an error and persists no partial response.
- [x] Existing generic conversion behavior used by Seal and WooCommerce remains unchanged.

## TDD cases

- `EUR order date and conversion` — exchange-rate model spec; write the failing example first and expect EUR 100 at rate 1.1250 to become USD 112.50 with the rate and effective date returned.
- `weekend order` — exchange-rate model spec; expect the preceding ECB publication date and its rate.
- `empty, fresh, and stale cache` — model/client specs; expect one full-history request, zero fresh-cache requests, and one recent-feed request.
- `successful refresh without a new rate date` — model spec; expect freshness to advance and the next conversion to make no request.
- `many conversions after one refresh` — model spec; expect stored-row lookups with no additional HTTP request.
- `provider and missing-rate failures` — WebMock-backed model specs; expect an error and no partially stored batch.
- `Seal and Woo compatibility` — existing focused specs; expect current generic conversion results to remain unchanged.

## Anchors

- `app/models/exchange_rate.rb:18-50` — current conversion, median fallback, and one-time cache population.
- `app/services/ecb/exchange_rates_client.rb:7-35` — current full-history request and response parsing.
- `spec/models/exchange_rate_spec.rb:45-166` — current conversion, cache, and provider-failure seams.
- `spec/services/ecb/exchange_rates_client_spec.rb:8-50` — ECB client compatibility seam.

## Non-goals

No Shopify parsing, generic cross-currency redesign, concurrency lock, scheduled refresh, retry layer, or Seal/Woo behavior change.

## Focused verification

- `mise exec -- bin/rspec spec/models/exchange_rate_spec.rb spec/services/ecb/exchange_rates_client_spec.rb spec/jobs/woo/pull_sales_job_spec.rb spec/models/sale_payment_plan/seal/parser_spec.rb` — proves dated conversion, bounded caching, provider failure, and unchanged existing consumers.
- `mise exec -- bundle exec rubocop app/models/exchange_rate.rb app/services/ecb/exchange_rates_client.rb spec/models/exchange_rate_spec.rb spec/services/ecb/exchange_rates_client_spec.rb` — checks affected Ruby code; include any new ExchangeRate-owned files.
- `git diff --check` — checks patch whitespace.
