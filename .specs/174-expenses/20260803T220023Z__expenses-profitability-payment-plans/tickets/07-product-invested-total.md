# 07. Show total purchase spend on the product card

Spec: ../spec.md
Status: done
Blocked by: none

## What to build

The product economics block answers "did this product make money", but not "how much have we put into it" — the figure is computed on the backend and never rendered. Worse, the block is hidden entirely until the product has sales, which is exactly the case where spend is the only number that exists.

The total must be computed over every purchased unit directly, not by adding the sold-unit cost to the unsold-stock cost: the first of those is limited to active and completed sales, so units linked to cancelled sales would fall through both.

## Acceptance criteria

- [x] The product card shows total money invested in purchasing the product.
- [x] The figure includes units linked to cancelled sales, which the two partial sums would each miss.
- [x] A product with purchases and no sales renders the block and its invested figure; the profit equation stays hidden until there is revenue.
- [x] The product-level figure carries a name distinct from the existing per-variant purchase-cost column, which is computed over a different set of purchases.
- [x] The block states that purchases never received into a warehouse are not counted, rather than silently omitting them.
