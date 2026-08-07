# 06. Make Shopify line-item truncation visible and measure query cost

Spec: ../spec.md
Status: done
Blocked by: none

## What to build

Orders are imported with a capped number of line items and no way to tell whether anything was cut, so a large order silently loses products. Before changing the cap, establish two facts: whether truncation happened, and how much Shopify query-cost budget the current pull actually uses. The shared field set already requests a large nested payment-schedule connection while orders are fetched in large batches, so raising another nested limit could push the query over Shopify's ceiling.

The remedy itself is deliberately deferred to a follow-up decision recorded in the spec's open proposals.

## Acceptance criteria

- [x] The order query reports whether more line items exist beyond those returned.
- [x] An order that was truncated is surfaced loudly rather than imported quietly as if complete.
- [x] The Shopify API response's cost and throttle information is retained and logged instead of being discarded.
- [x] Measured request cost and remaining budget for the bulk sales pull are recorded in the spec's open proposals so the cap decision can be made on numbers.
- [x] No change is made to the line-item cap in this ticket.

## Notes

- `lineItems(first: 10)` now also selects `pageInfo { hasNextPage }`; the cap itself is untouched.
- `Shopify::Api::Client` reports truncated orders through `Rails.logger.error` and `Sentry.capture_message` at `:error`, and logs `extensions.cost` before raising on errors, so a throttled response still leaves its throttle status behind. `fetch_orders` returns the same figures under a new `:query_cost` key.
- The cost recorded in the spec's P1 is **structurally derived from the query shape, not measured against live Shopify** — the ticket forbids a real API call. P1 states this explicitly, shows the arithmetic, and names the log line that will produce the authoritative number on the first production pull.
- Out of scope, found in passing: the derivation puts `orders(first: 250)` far above Shopify's documented 1000-point single-query ceiling even at `main`'s field set, which would make the bulk pull fail with `MAX_COST_EXCEEDED` — an HTTP 200 with `errors`, i.e. exactly the unretried path in P2.
