# 03. Show payment-plan context on Sales pages

Spec: ../spec.md
Status: done
Blocked by: 02

## What to build

Extend the Sales Inertia contract and render compact payment-plan context on the index plus a conditional order-level payment-plan block on show.

## Acceptance criteria

- [x] Generic partial Sales show `Partially paid` only when received and outstanding amounts are both positive.
- [x] Origin and child installment Sales keep their order progress and show exact plan progress/position.
- [x] Deposits show their percentage and supported projected money without rendering `1 of 1`.
- [x] Multiple plans render separately and unsupported projections are omitted.
- [x] Sales show renders the order-level payment-plan block directly below the header only when relevant.
