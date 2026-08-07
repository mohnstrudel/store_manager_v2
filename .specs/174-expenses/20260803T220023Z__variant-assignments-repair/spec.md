# Enforce Variant Assignments with In-App Repair

## Problem

Purchases and SaleItems can currently omit a Variant or reference a Variant from another Product. PurchaseItem links can also connect records that do not share an exact Product and Variant. Normal forms, importers, jobs, and manual linking do not share one assignment rule. Historical repair is therefore required before Variant identity can be enforced with database constraints.

## Goal and approach

Make Product and Variant identity explicit and consistent for every Purchase, SaleItem, and PurchaseItem. Product owns assignment availability and the Base Model lifecycle. Normal write paths use assignable Variants and notify customers for new links or relinks. A live administrator-only repair page uses a private silent repair command for historical integrity work. Migrate with an idempotent dry-run-first backfill, then contract the schema only after the integrity query reports zero issues.

## Approved decisions

- **Approved — vocabulary:** `Product::VariantAvailability`, `product.assignable_variants`, `product.variant_repair_candidates`, `Variant::AssignmentIntegrity`, and `Variant::AssignmentRepair`.
- **Approved — definitions:** A Base Model has nil size, version, and color. A real Variant is any Variant for which `product.base_variant?(variant)` is false.
- **Approved — current behavior:** Product creation builds a Base Model, but Base activation is not synchronized with real Variants; Purchase and SaleItem Variant identity can be missing or mismatched; linking can match by Product alone; purchase forms may auto-select the first Variant; manual Sale rows have no Variant selector; repair is manual and scattered.
- **Approved — proposed availability:** Every Product has exactly one Base Model and at least one active Variant. Under a Product lock, the first active real Variant deactivates Base and removing/deactivating the last active real Variant reactivates Base. Users and integrations cannot directly toggle Base. Product-owned destruction remains possible.
- **Approved — normal candidates:** `assignable_variants` returns active real Variants when any exist, otherwise active Base. A missing Variant normalizes to Base only while Base is assignable. New or changed identity must use an assignable same-Product Variant.
- **Approved — historical candidates:** `variant_repair_candidates` adds same-Product deactivated real Variants, labeled historical, but never exposes a deactivated Base while real Variants are active. An unchanged same-Product deactivated reference remains valid historical identity.
- **Approved — public read contract:** `GET /products/:product_id/assignable_variants` returns `mode: "base" | "select"` and `variants: [{ value, label, base_model }]`.
- **Approved — forms:** Base mode submits fixed Base. Select mode requires an explicit real Variant and never auto-selects the first option. Changing Product clears Variant. Manual Sale rows persist `variant_id` and expose row-specific errors.
- **Approved — initial Product purchase:** Draft Variants use stable `client_key` values and Purchase submits `variant_client_key`. Active draft real Variants suppress draft Base; removing/deactivating the last restores Base. Resolution happens after Variants save inside the existing Product transaction, and any failure rolls back the entire Product/Purchase/items/payment operation.
- **Approved — PurchaseItem identity:** Add derived non-null `product_id` and `variant_id`, copied from Purchase. Enforce composite references to Purchase and, when linked, SaleItem. Remove arbitrary `sale_item_id` assignment from general PurchaseItem and warehouse parameters.
- **Approved — linking:** Lock SaleItems and PurchaseItems in ascending ID order, recheck exact Product/Variant and capacity under lock, and commit a link batch atomically. Parent identity changes first unlink incompatible PurchaseItems and then exact-match relink within capacity.
- **Approved — notifications:** Every normal new link or relink notifies after the outermost transaction commits, including manual, replacement, bulk, Sale editing, Purchase creation/warehousing, and integration-driven flows. Deduplicate IDs within a command. Repeating an existing link is a silent no-op; unlink without replacement is silent.
- **Approved — silent boundary:** Only `Variant::AssignmentRepair`, called by the historical backfill and admin repair endpoints, may relink silently. Normal controllers and jobs accept no silent parameter. Existing Sidekiq mail retry behavior remains unchanged.
- **Approved — integrity UI:** `Variant::AssignmentIntegrity` is a read-only live query, not a persisted issue table. `/variant_assignment_issues` is administrator-only and has URL-backed tabs, counters, and pagination for broken Purchase assignments, broken SaleItem assignments, and incompatible PurchaseItem links.
- **Approved — repair actions:** Purchase and SaleItem rows choose from `variant_repair_candidates`. Link repair silently unlinks the mismatch and relinks exact available inventory only when capacity exists. Repairs recheck under locks; stale resolved rows are successful no-ops; resolved rows disappear after Inertia reload.
- **Approved — interface text:** Navigation label is `Variant Repairs`; empty state is `No Variant assignment issues`.
- **Approved — Woo boundary:** Do not change Woo pull, webhook, scheduling, transactions, refresh, status transitions, or shutdown. Keep syncing while active Woo orders remain. Historical backfill performs no Woo network calls. Existing rows retain a stored Variant when incoming Woo data omits resolvable metadata. Unexpected invalid new lines fail through existing reporting.
- **Approved — backfill:** Provide an idempotent, resumable command that is dry-run by default and mutates only with `APPLY=1`. Recalculate all planning counts at runtime.
- **Approved — deterministic repair order:** Synchronize Base activation; atomically reconcile duplicate Shopify Variant identities; repair deterministic Purchases and SaleItems; backfill PurchaseItem identity; silently repair deterministic mismatches; expose unresolved records in the repair UI.
- **Approved — contraction gate:** Apply final non-null, composite Product/Variant foreign keys, one-Base-per-Product, and nonblank Variant StoreInfo uniqueness only after all integrity counts reach zero. Then remove legacy nil-Variant fallbacks.

## Contracts

### Domain Contract

- **Owner and boundary:** Product owns Base lifecycle and assignment availability. Purchase and SaleItem own their persisted Product/Variant identity. PurchaseItem owns its SaleItem link and derived identity. `Variant::AssignmentIntegrity` owns cross-record inspection. `Variant::AssignmentRepair` is the sole silent writer, reachable only through administrator repair resources and the backfill.
- **State:** Product/Variant identity and activation are authoritative database state. External StoreInfo identifiers are imported external identity. PurchaseItem Product/Variant is derived from Purchase at creation and constrained against both link endpoints. Integrity rows and counts are live derived state.
- **Invariants:** Exactly one Base per Product; at least one active Variant; Base active only without active real Variants; same-Product identity everywhere; normal changes use assignable Variants; historical unchanged deactivated real identity remains valid; linked PurchaseItems exactly match Purchase and SaleItem identity; SaleItem link capacity is never exceeded.
- **Commands:** Product synchronizes Variant availability under lock. Purchase and SaleItem identity commands normalize or validate assignment and reconcile links. PurchaseItem link commands lock, validate, mutate atomically, and schedule deduplicated post-commit notifications. `Variant::AssignmentRepair` performs locked silent repairs.
- **Inspection and recovery:** Administrators use the live repair page. The backfill logs counts/failures, resumes idempotently, and defaults to dry-run. The zero-issue integrity query gates schema contraction. No CSV issue queue or network re-resolution is required.
- **Tests:** Model/request/job specs cover lifecycle, concurrency, validation, authorization, locking, capacity, rollback, notifications, silent repair, integrations, backfill, and database constraints.

### Frontend Contract

- **Owner and boundary:** Purchase and Sale forms own their Product/Variant selection state and consume the Rails availability endpoint. Product form owns draft Variant keys and draft purchase selection. `VariantAssignmentIssues/Index` owns URL-backed issue presentation and repair interactions. Rails remains the authority for candidates, validation, authorization, and repair.
- **State:** Persisted records and Inertia props are authoritative. Product selection, explicit Variant choice, draft client keys, open inline editor state, and pending form state are page/component state. Tab, page, and filters are URL state. Labels, counts, and mode presentation are derived.
- **Invariants:** React never invents Base or historical eligibility. Changing Product clears Variant. Select mode has no implicit first choice. Repair candidates come only from Rails. Shared inline editing owns generic form lifecycle; the page owns issue reload scope.
- **Commands and transitions:** Load candidates on Product change with stale-response protection; submit one form command; reload issue rows, counts, and pagination after repair. Cover loading, base, select, empty, validation-error, stale-row no-op, and successful disappearance.
- **Inspection and recovery:** Visible row errors preserve selection. Failed repairs remain visible and retryable. URL state makes issue views reloadable. Successful repairs refresh all issue props.
- **Tests:** Request specs own JSON/Inertia contracts and authorization. Component tests cover selection and issue interactions. Focused browser coverage proves Rails/Inertia error and reload lifecycles where component tests cannot.

## Boundaries and non-goals

- Do not redesign or disable Woo synchronization.
- Do not call Woo during historical backfill.
- Do not approximate ambiguous option-product history or weaken Variant constraints for Woo.
- Do not persist an integrity-issue table or require CSV-based manual repair.
- Do not expose silent notification suppression to ordinary controllers, forms, jobs, or integrations.
- Do not treat planning snapshot counts as migration constants.

## Testing decisions

- Use failing focused tests before each behavior slice.
- Cover Base activation, concurrency, direct-toggle rejection, Product destruction, normal/historical candidates, Base normalization, explicit real selection, cross-Product rejection, and draft transitions.
- Cover composite foreign keys, ordered locks, capacity, atomic rollback, identity-change reconciliation, direct-assignment prevention, notification timing/deduplication/no-ops, and silent repair.
- Cover repair authorization, filters, URL pagination, inline errors, stale rows, impact counts, repair candidates, and link repair.
- Cover Shopify external identity reconciliation, Woo full-refresh/status regressions, dry-run safety, `APPLY=1`, idempotency, resumability, unresolved handoff, and zero-issue constraint gating.
- After every ticket and final integration, run the complete RSpec, Vitest, Oxlint, Oxfmt, and TypeScript gate from `AGENTS.md`.

## Open proposals

None.
