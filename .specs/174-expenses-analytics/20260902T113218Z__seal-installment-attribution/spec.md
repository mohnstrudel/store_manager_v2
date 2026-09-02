# Deterministic Seal installment attribution

## Problem

A Seal follow-up payment reaches Shopify as a normal order whose line item is the generic `Teilzahlung / Partial Payment` product. Neither that Shopify item nor Seal's subscription item identifies the purchased merchandise.

Seal does provide the authoritative relationship: the subscription `order_id` identifies the origin Shopify order and each completed billing attempt `order_id` identifies a payment order. The current `Sale::InstallmentProductResolver` instead runs during sale-item import and combines customer-history guesses, equal-total matching, provider requests, and product writes. Its result can depend on import order because Shopify and Seal currently synchronize in parallel and Shopify imports newest orders first.

## Goal and approach

Use Seal order IDs to persist origin/payment relationships, synchronize Shopify before Seal, then run one database-only attribution job. The job derives merchandise only from the persisted origin Shopify sale. It never asks Seal or Shopify and never guesses from customer history.

Exactly one eligible origin item permits attribution. Missing or multiple eligible items remain explicitly unresolved on the generic Seal product.

## Approved decisions

### Provider authority

- **[approved]** Seal subscription and billing-attempt order IDs are the only authority for plan membership.
- **[approved]** Customer, title, total, date proximity, and product guesses are not identity signals.
- **[approved]** Shopify imports the provider-reported generic partial-payment item normally. Sale ingestion does not resolve the merchandise.
- **[approved]** Seal item product data is not authoritative for the real merchandise.

### Ordered synchronization

- **[approved]** The bulk sales action stops enqueueing Seal in parallel. A terminal successful Shopify sales page enqueues one Seal sync; intermediate and failed pages do not.
- **[approved]** A successful limited Shopify pull also enqueues Seal after its processed page. A single-order pull never starts a full Seal sync.
- **[approved]** Seal synchronization is single-flight under one PostgreSQL advisory lock.
- **[approved]** A successful complete Seal sync enqueues one full attribution job. A failed sync enqueues none.

### Database-only attribution

- **[approved]** `SalePaymentPlan` owns attribution orchestration because it stores both the origin sale and linked payment sales. The job is delivery only.
- **[approved]** A small `Sale`/`SaleItem` command applies or clears a supplied origin item; it does not discover provider relationships.
- **[approved]** A follow-up sale is eligible only through an active Seal plan part linked to that sale and distinct from the plan's origin sale.
- **[approved]** Exactly one eligible catalog, non-installment origin sale item assigns `origin_sale_item`, product, and variant to the payment item.
- **[approved]** Missing records or zero/multiple eligible origin items leave the payment generic and unassigned.
- **[approved]** Reconciliation is idempotent and authoritative: it corrects an old guess when unique and clears unsupported attribution when ambiguous.
- **[approved]** The attribution path performs no provider request, product pull, currency conversion, purchase linking, or customer-wide search.
- **[approved]** A single-order pull may enqueue attribution scoped to that sale when a persisted plan already links it.

### Rollout and cleanup

- **[approved]** Run the ordered workflow over accessible history, audit resolved and unresolved cases, and verify idempotence.
- **[approved]** Remove `Sale::InstallmentProductResolver`, `Sale::InstallmentBackfill`, their tasks/specs, and every live reference only after the audit succeeds.

## Contracts

### Seal relationship synchronization

- **Owner:** `Seal::SyncPaymentPlansJob` owns provider iteration; the Seal parser translates subscriptions; `SalePaymentPlan` persists origin and payment-sale links.
- **Invariant:** only normalized Seal order IDs establish relationships; incomplete provider synchronization never triggers attribution.
- **Recovery:** retry the idempotent Seal sync after provider or missing-order recovery.

### Installment attribution

- **Owner:** `SalePaymentPlan` selects linked sales and the eligible origin item; `Sale`/`SaleItem` applies the derived relationship; `Seal::ReconcileInstallmentSaleItemsJob` invokes the command.
- **Invariant:** one eligible origin item resolves; zero or multiple stays generic; repeated runs converge without provider access.
- **Inspection:** report resolved unique cases, missing records, and ambiguous origin orders separately.

## Boundaries and non-goals

- Currency conversion, ECB caching, plan projections, and USD presentation are specified separately in [the USD currency provenance spec](../20260902T113218Z__usd-currency-provenance/spec.md).
- No multi-product allocation, customer-history fallback, new resolver/service object, or full Seal sync after a single-order pull.
- Implement this spec after the currency spec to avoid conflicts in shared `SalePaymentPlan` and Seal synchronization files.

## Testing decisions

Write failing contract examples before behavior changes. Cover exact order-ID relationships, terminal Shopify-to-Seal handoff, Seal single-flight behavior, success-only attribution enqueueing, database-only unique/ambiguous/missing attribution, correction of historical guesses, scoped repair, and idempotence. Explicitly assert that attribution constructs no Shopify or Seal client.

The operational audit records relationship counts, deterministic resolutions, unresolved ambiguous cases, and a no-change rerun before cleanup.

## Open proposals

None.
