# 08. Distinguish follow-up payments from the original order

Spec: ../spec.md
Status: done
Blocked by: none

## What to build

When a customer pays in instalments, every charge becomes its own sale, and in the sales list those follow-up charges are indistinguishable from ordinary orders — the plan context exists but renders as easily-missed text inside the payment column. Make the relationship visible: a follow-up charge should read as belonging to its originating order and link to it.

Grouping rows on the server is out of scope: the list is paginated and sorted by store date, so an order and its final instalment usually sit on different pages. The affiliation is conveyed visually instead.

## Acceptance criteria

- [x] A follow-up payment row in the sales list is visually subordinate to ordinary rows and states its position in the plan.
- [x] The follow-up row links to its originating order; the originating row is marked as carrying a plan.
- [x] The sale page header shows the same marker, so the relationship is visible without scrolling to the payment card.
- [x] The originating sale lists its follow-up payments with links; a follow-up sale links back to the origin.
- [x] The customer's sales table carries the same marker, where instalments otherwise look like duplicate orders.
- [x] The marker's meaning is carried by its text, not by colour alone, and indentation and muting come from a named style rather than inline utilities.
- [x] Pagination, sorting, and search on the sales list behave exactly as before.
