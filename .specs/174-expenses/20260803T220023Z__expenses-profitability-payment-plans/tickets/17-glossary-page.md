# 17. Publish the money glossary as a page

Spec: ../spec.md
Status: done
Blocked by: none

## What to build

The app shows twenty-odd financial figures and no definition of any of them. Two of those words
mean different things on adjacent columns of one table. Tooltips help where they exist, but they
are scattered, one of them is wrong, and a reader who wants to compare two terms has to hover them
one at a time on different pages.

Publish one page that defines every money term the app uses, in plain language, each with a worked
example. Make it reachable from the navigation and from every tooltip, so the question "what does
this number mean" always has one answer in one place.

Anyone signed in can read it. Warehouse staff read these words on the pages they use; a definition
is not privileged information.

This ticket writes the definitions. Ticket 18 makes the interface match them.

## Acceptance criteria

- [x] A glossary page exists at a stable address and lists every money term the app displays.
- [x] Each entry is one plain sentence plus a worked example with real numbers.
- [x] Terms that are easily confused say plainly how they differ from each other.
- [x] Any signed-in user can open it; it is not restricted to administrators.
- [x] It is reachable from the navigation without administrator rights.
- [x] A financial label's tooltip links to that term's entry.
- [x] Opening a term's link lands on that term, not at the top of the page.

## Anchors

- `config/routes.rb:43-45` — the neighbourhood for a non-resource `get` route
  (`get "debts", to: "dashboard/debts#show"`). Line `141` shows how reference-data resources are
  declared, for contrast.
- `app/controllers/concerns/authorization.rb:15-18` — `authorize_resource` calls
  `authorize controller_name.singularize.to_sym` before every action, and `verify_authorized` runs
  after. A new controller inherits this; a matching policy must exist or every request raises.
- `app/policies/application_policy.rb:19-35` — every predicate defaults to `admin?`, so the policy
  must override `show?` explicitly. `app/policies/expense_rate_policy.rb` is the shape to follow.
- `app/frontend/components/app-navigation/AppNavigation.tsx:107` — `overflowLinks`, rendered at
  `:303` for every user. `:155` — `adminLinks`, rendered at `:304` only when
  `user?.role === "admin"`. The glossary belongs in the first.
- `app/frontend/components/profitability/MetricLabel.tsx` — wraps a `TipMark` in `.metric_label`;
  this is where the link into the glossary goes, so every existing hint gains it at once.
- `app/frontend/components/profitability/metricLabels.ts` — the current hints, including the
  `netProfit` one that is wrong on the sale page. Ticket 18 fixes the hint text; this ticket needs
  the anchor ids to line up with these keys.
- `docs/plain-language.md` — the writing standard these entries must follow.

## Entry format

> **Projected total** — the full price of the deal, including the parts the customer has not been
> charged for yet. A 1 000 € order paid as a 30 % deposit shows a Total of 300 € and a Projected
> total of 1 000 €.

## Terms to define

| Concept | Label | Backend name |
|---|---|---|
| Full order value, paid or not | Revenue | `expected_revenue` |
| Money in hand | Received | `received_revenue` |
| Money still owed by the customer | Outstanding | `outstanding_revenue` |
| Money returned to the customer | Refunded | `refunded_revenue` |
| Full contract value of a payment plan | Projected total | `projected_total` |
| Still to be charged under the plan | Projected remainder | `projected_remainder` |
| Landed cost of sold goods, all in | COGS | `purchase_cost` |
| COGS less direct expenses | Merchandise cost | `merchandise_cost` |
| Ad-hoc costs booked on a purchase item | Direct expenses | `purchase_item.expenses` |
| Overhead estimated as a share of revenue | OpEx | `business_expenses` |
| The configurable overhead percentages | OpEx rates | `ExpenseRate` |
| Recorded overhead actuals | OpEx records | `OperationalExpense` |
| Revenue − COGS − OpEx | Net profit | `expected_final_profit` |
| Received − COGS − OpEx | Profit in hand | `realized_profit` |
| Projected total − COGS − OpEx | Projected net profit | `projected_final_profit` |
| Landed cost of every purchased unit | Invested | `invested_total` |
| Landed cost of unsold units | Unsold stock value | `remaining_inventory_cost` |
| A variant's hand-entered reference price | List cost | `variant.purchase_cost` |
| Actual landed spend for one variant | Total landed cost | `total_purchase_cost` |
| Money owed to a supplier | Supplier debt | `Purchase#debt` |
| Units sold beyond units purchased | Unit shortfall | dashboard debt reporting |
| A charge that is part of a payment plan | Payment | `is_follow_up_payment` |

Pairs that must state their difference explicitly, because each is currently one word doing two
jobs: **List cost** vs **Total landed cost**; **Supplier debt** vs **Unit shortfall**; **Revenue**
vs **Received** vs **Projected total**; **COGS** vs **Merchandise cost** vs **Invested**;
**Net profit** vs **Profit in hand** vs **Projected net profit**.

## Non-goals

- The glossary is page content in the repository, not editable from the interface and not stored
  in the database.
- Do not rename any interface label here; ticket 18 owns the rename.
- Do not add a search or filter to the page.

## Focused verification

```bash
mise exec -- bin/rspec spec/requests/glossary_spec.rb
```

```bash
mise exec -- pnpm exec vitest run app/frontend/pages/Glossary/Show.test.tsx app/frontend/components/app-navigation/AppNavigation.test.tsx app/frontend/components/profitability/MetricLabel.test.tsx
```
