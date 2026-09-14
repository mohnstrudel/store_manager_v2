# Seal installment total correction

## Problem

Sale 15057 is the origin of Seal subscription 14618326 for product 4977. The user confirms that its product contract is EUR 450 and cannot be lower.

The local records show real installment charges, not a EUR 450 product price:

- Shopify order 7554629468489 records EUR 56.25 merchandise plus EUR 20 shipping. At its recorded EUR-to-USD rate of 1.1448, the sale total is USD 87.29 and its item amount is USD 64.40.
- Seal subscription 14618326 records eight billing cycles and EUR 56.25 for each recurring merchandise charge, plus EUR 20 shipping. Its seven future or completed scheduled attempts confirm the eight-payment schedule.
- The associated Seal selling-plan rule says “Pay in 4 months” and has a 75% adjustment. It is not the subscription’s eight-cycle schedule.

`SalePaymentPlan::Seal::Parser#projected_total` always reconstructs a full value by dividing one recurring charge by the selling-plan percentage. It therefore calculates EUR 56.25 / 25% + EUR 20 = EUR 245, stored as USD 280.48. For an installment subscription it must use the subscription’s actual eight charges: EUR 56.25 × 8 + EUR 20 = EUR 470, or USD 538.06 at the recorded rate.

That erroneous projection flows unchanged to:

- `SaleHelper#sale_plan_payment_progress_props` and `PlanProgressBar`, which render payment progress against USD 280.48.
- `SalePaymentPlan#profitability`, which reports USD 280.48 as gross revenue.

The sale-item table also labels the origin order’s USD 87.29 installment charge as `Price`. The charge is historically correct, but it is not the product’s contracted price.

Evidence:

- Product 4977 / variant 16325 was created with selling price EUR 450 and has no later price audit.
- Sale 15057 and item 15448 contain USD 87.29 / USD 64.40 after the order-date conversion.
- Payment plan 24 contains eight parts and USD 280.48.
- The current Seal response for subscription 14618326 contains `billing_max_cycles: 8`, `final_amount: 56.25`, `delivery_price_discounted: 20`, while the referenced selling-plan rule has `billing_max_cycles: 4` and a 75% adjustment.
- `Sale::Shopify::Parser` correctly imports the actual order charge from Shopify; it is not the source of the projection defect.

## Goal and approach

Calculate recurring Seal contract value from the subscription’s recurring charge and its own billing-cycle count, not from a subscription-rule discount percentage. Preserve Shopify’s actual installment orders and payments. On the originating sale, show the contract product price separately from the charge collected for that installment.

Observable success:

- An eight-cycle EUR 56.25 recurring charge with EUR 20 shipping projects EUR 470, then USD 538.06 at the origin order’s 1.1448 rate.
- Sale 15057 retains its imported USD 64.40 merchandise charge, USD 22.90 shipping, USD 87.29 order total, and USD 87.29 collected amount.
- Plan 24 then renders its collected amount against USD 538.06, and its profitability card reports USD 538.06 gross revenue.
- The origin sale identifies USD 87.29 as the installment charge and shows the contracted merchandise price separately; follow-up payment pages continue to hide product rows.
- A provider rule whose stated cycle count differs from the subscription cannot reduce the recurring contract total.

## Approved decisions

- **Approved — recurring schedule authority.** For a Seal installment plan, `subscription.billing_max_cycles` and each recurring item’s `final_amount` define the merchandise contract value. The selling-plan rule does not define the number of charges for an already-created subscription.
- **Approved — deposit authority remains unchanged.** A one-part deposit still reconstructs its contract total from its authoritative percentage adjustment and adds shipping once.
- **Approved — shipping is charged once.** Add the subscription’s discounted delivery price, falling back to delivery price, once after calculating the recurring merchandise total.
- **Approved — historical charges remain authoritative.** Shopify order and sale-item amounts remain the amount actually invoiced or collected for that installment. Do not rewrite sale 15057, its item, or follow-up-sale revenues to the EUR 450 catalog price.
- **Approved — contract-price presentation.** The originating sale must distinguish the full contracted product price from the amount charged for this installment. The existing product-table `Price` cell becomes the contract price when a known Seal plan covers the origin; show the existing order/item amount as `Installment charge`. Non-plan and deposit sales retain their existing price presentation.
- **Approved — recovery through normal writers.** Fix the parser, rerun the existing Seal sync, and let `SalePaymentPlan.reconcile!` update plan 24. Do not patch `projected_total` directly because the next sync would overwrite it.
- **Proposal — upstream guard.** Add a read-only incident signal when a recurring subscription’s reconstructed merchandise total is below the linked origin product’s known catalog value in the same source currency. It must not reject, rewrite, or silently discard Shopify transactions. Decide the operator-facing destination for this signal before implementation; no new persistence, notification, or provider write is approved yet.

Current behavior: recurring plans derive their total from a recurring payment and a selling-plan percentage. A mismatched rule can halve an eight-payment contract; the origin sale labels one installment as the product price.

Proposed behavior: recurring plans derive their total from their own scheduled payment count; sale details identify the contract price and the individual charge truthfully.

## Contracts

### Domain Contract — Seal plan projection

- **Owner and boundary:** `SalePaymentPlan::Seal::Parser` translates the provider subscription snapshot. `SalePaymentPlan.reconcile!` is the only writer for the plan and its parts. `Seal::SyncPaymentPlansJob` owns scheduled refresh and recovery.
- **State:** Seal subscription `billing_max_cycles`, recurring item `final_amount`, and discounted delivery price are external authoritative inputs. `SalePaymentPlan#projected_total` is a persisted USD projection derived at the linked origin sale’s recorded exchange rate. Shopify sale and sale-item values are external authoritative transaction records. `Variant#selling_price` is catalog state, not a writer for historical charges.
- **Invariants:** For an unambiguous recurring plan, projected merchandise equals the sum of all recurring item amounts multiplied by the subscription cycle count; projected total adds delivery once. A one-part deposit keeps the percentage reconstruction. A selling-plan rule cannot override the subscription’s cycle count. Reconciliation remains transactional and idempotent.
- **Commands:** `Seal::SyncPaymentPlansJob#perform` parses each subscription and calls `SalePaymentPlan.reconcile!`; no controller or UI writes payment-plan economics.
- **Inspection and recovery:** Inspect subscription 14618326’s recurring charge, billing-cycle count, delivery charge, and origin order’s stored exchange rate; rerun the Seal sync; then inspect plan 24, sale 15057, and its existing parts. A failed sync preserves its previous snapshot. Do not manually edit the derived plan total.
- **Tests:** Parser specs own raw-provider arithmetic and foreign-currency conversion. Sync-job specs own parser-to-persistence reconciliation. Plan model specs own gross-revenue consumption of the persisted total. Helper/request tests own the serialized monetary boundary.

### Frontend Contract — sale price presentation

- **Owner and boundary:** `SaleHelper#sale_show_item_props` exposes explicit contract-price and installment-charge values. `Sales/Show/Items` renders them; it does not recompute money or infer plan membership. `Sales/Show/Details` and `PlanProgressBar` continue to render the plan projection supplied by Rails.
- **State:** Rails sale-show props are the only client state. Contract price, installment charge, payment progress, and gross revenue are deterministic server-derived values with request lifetime only.
- **Invariants:** The UI never calls a single installment charge the product price when a known recurring plan supplies the full contract price. It preserves actual charge visibility and leaves follow-up payment pages without product rows.
- **Commands and transitions:** Read-only rendering. A Seal sync or sale pull changes persisted inputs; the next Inertia visit renders the new values. No browser write, loading state, or optimistic state is introduced.
- **Inspection and recovery:** The sale page presents the contract price, installment charge, plan progress, and profitability from one server response. After a sync failure, the displayed prior snapshot remains visible until a successful retry.
- **Tests:** Focused helper/request coverage proves Rails emits the two distinct amounts; the existing `Sales/Show/Items` Vitest seam proves the user-visible labels and values. No browser-only behavior changes.

## Boundaries and non-goals

- Do not change Shopify order import, exchange-rate selection, or actual collected/payment amounts.
- Do not use current catalog price to overwrite or floor individual installment orders; discounts, deposits, and follow-up payments can legitimately be lower than the full contract value.
- Do not alter deposit-plan projection or Shopify payment-terms behavior.
- Do not add a manual override, compatibility path, provider write, migration, or a second projection store.
- Do not implement the proposed underpricing signal until its operator-facing owner and delivery behavior are approved.

## Testing decisions

- **Seal parser — failing test first:** add a sanitized regression subscription with eight cycles, EUR 56.25 recurring merchandise, EUR 20 shipping, and a conflicting four-cycle/75%-adjustment selling-plan rule. Assert a EUR 470 projection before conversion and USD 538.06 with the recorded 1.1448 rate. Assert that the one-part deposit formula remains unchanged.
- **Sync job — failing test first:** reconcile the same snapshot through `Seal::SyncPaymentPlansJob` and assert persisted `projected_total` is USD 538.06 while the plan still contains eight parts and its existing origin/part links.
- **Profitability and helper boundary — failing test first:** use a recurring origin sale with a plan total of USD 538.06 to assert gross revenue and progress use the corrected plan total, while the originating item preserves its USD 87.29 installment payment.
- **Sale-show serialization and UI — failing test first:** assert the server sends an explicit contract price plus installment charge for an origin item, and `Sales/Show/Items` renders the contract price and the `Installment charge` label. Assert ordinary sale rows still render their existing single price.
- **Focused verification:** run the affected parser, sync-job, payment-plan, sale-helper/request, and `Sales/Show/Items` tests; run the applicable Ruby and TypeScript static checks. Use the actual sale page after a targeted sync to visually confirm the three reported values.

## Open proposals

- Add an operator-visible, read-only underpricing signal for recurring subscriptions whose reconstructed contract merchandise total conflicts with the linked catalog price. The source of truth, threshold, route or dashboard owner, and notification policy need approval before implementation.
