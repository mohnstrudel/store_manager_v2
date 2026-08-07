# 04. Fix payment progress display

Spec: ../spec.md
Status: done
Blocked by: none

## What to build

Make the sale payment bar tell the truth in two cases it currently gets wrong: an item nobody has paid for yet, and an order whose Shopify total was edited after the fact. Money formatting returns nothing for zero, so a caption that interpolates it without a fallback renders a dangling "of" phrase. Separately, the bar's percentage and its middle number are computed from different totals, so they disagree on edited orders.

## Acceptance criteria

- [x] A sale item with nothing received renders an explicit "not paid" marker instead of a blank followed by "of <total>".
- [x] The payment progress type admits the empty values the server actually sends, and every caption variant handles them.
- [x] Paid plus debt equals the displayed price in every payment bar on the sale page and the sales index.
- [x] The order total shown in the sale details card is unchanged; it stays the order's own total and is not conflated with the payment basis.
- [x] The existing request spec asserting the sales index payment price is updated to the new basis, with the expected value derived by hand.
