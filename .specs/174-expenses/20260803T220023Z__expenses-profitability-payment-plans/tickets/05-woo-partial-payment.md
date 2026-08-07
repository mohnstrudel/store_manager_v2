# 05. Stop claiming full payment on Woo partial payments

Spec: ../spec.md
Status: done
Blocked by: 04

## What to build

A WooCommerce order marked partially paid currently records as fully paid, because the importer decides payment purely from the presence of a payment date, and Woo sets that date on deposits too. WooCommerce gives us no deposit amount, so record the split as unknown rather than inventing one — and make sure "unknown" survives to the screen instead of silently becoming zero.

## Acceptance criteria

- [x] A Woo order whose status is partially paid records its expected revenue but leaves received and outstanding amounts unset.
- [x] Revenue allocation writes only the amounts that are actually known; unset order-level amounts do not become zeros on the sale items.
- [x] Allocation behavior for Shopify orders, where all amounts are known, is unchanged.
- [x] The sale page shows the payment as unknown, not as zero percent collected, and the payment card does not disappear for these sales.
- [x] A fixture reproducing a real partially paid Woo payload is added, and specs assert neither 100% nor 0% is claimed.
