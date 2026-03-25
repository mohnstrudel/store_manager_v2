# Store Manager v2

Store Manager v2 is a Rails 8 monolith for running collectible inventory operations across purchasing, warehousing, sales, and store sync.

At a high level, the app answers one business question end to end:

When a customer buys a product, which physical item fulfilled the order, where did it come from, what does it still cost us, and where is it now?

This repository is intentionally model-centric. The domain lives in `app/models`, controllers stay thin, jobs are transport shells, and integrations are attached to the owning domain concepts instead of floating in a generic service layer.

---

## Bird's-Eye View

### What the system manages

- product catalog for collectible goods
- variant modeling through editions, sizes, versions, and colors
- supplier purchases and partial payments
- per-unit inventory via `PurchaseItem`
- warehouse storage and warehouse-to-warehouse transitions
- customer sales from Shopify and WooCommerce
- linking sold line items to physical inventory
- store metadata and sync timestamps through `StoreInfo`

### Core business flow

```text
Catalog setup
  Franchise -> Product -> Edition

Inventory acquisition
  Supplier -> Purchase -> PurchaseItem -> Warehouse

Sales fulfillment
  Customer -> Sale -> SaleItem -> PurchaseItem

External sync
  Shopify / Woo payload -> Parser -> Importer -> Domain model
```

### The main invariant

The app tries to keep the sellable view and the physical view connected:

- `Product` and `Edition` describe what we sell
- `Sale` and `SaleItem` describe what customers ordered
- `Purchase` and `PurchaseItem` describe what we actually bought
- `Warehouse` and `WarehouseTransition` describe where inventory lives and how it moves

That lets us answer financial, logistics, and customer-service questions from one system instead of stitching together spreadsheets and store dashboards.

---

## Domain Map

```text
Franchise
  -> Product
    -> Edition
    -> Media
    -> StoreInfo
    -> Purchase
      -> Payment
      -> PurchaseItem
        -> Warehouse
        -> SaleItem
          -> Sale
            -> Customer

Warehouse
  -> WarehouseTransition

User
  -> Session
```

### Key aggregates

| Aggregate | Responsibility |
| --- | --- |
| `Product` | Catalog root. Owns title composition, edition generation, store references, media coordination, and sales history views. |
| `Edition` | Concrete sellable variant built from product option dimensions such as size, version, and color. |
| `Purchase` | Supplier-facing order with cost, quantity, payments, and inventory-linking rules. |
| `PurchaseItem` | One physical inventory unit with warehousing, shipping, notification, and sale-linking behavior. |
| `Sale` | Customer-facing order imported from stores, with status derivation and inventory-linking entry points. |
| `SaleItem` | One sold line item that can be matched to one or more `PurchaseItem` records. |
| `StoreInfo` | Polymorphic store metadata layer for Shopify and Woo records, IDs, timestamps, and sync checksums. |
| `Warehouse` | Physical storage location plus movement rules, listing, lifecycle behavior, and transitions. |

### Representative model areas

```text
app/models/product/
  editing.rb
  edition_generation.rb
  initial_purchase.rb
  listing.rb
  sales_history.rb
  store_info_editing.rb
  store_references.rb
  titling.rb
  shopify/
    importer.rb
    parser.rb
    payload.rb

app/models/purchase/
  financials.rb
  linking.rb
  warehousing.rb

app/models/sale/
  editing.rb
  linking.rb
  listing.rb
  shop_sync.rb
  statuses.rb
  shopify/
    importer.rb
    parser.rb
    sale_item_importer.rb
```

---

## Architecture, Layer by Layer

### 1. Request layer

Controllers are request adapters.

They are responsible for:

- loading the starting record or relation
- normalizing params
- choosing response format
- redirecting or rendering

They are not meant to be the home for business rules.

A representative example is `ProductsController`, which prepares params and calls model entry points such as `create_from_form!` and `apply_form_changes!`, while the transaction and domain sequencing live on `Product`.

### 2. Domain layer

The domain lives in `app/models`.

Each important aggregate has:

- a short base model file that acts as a composition root
- capability modules under `app/models/<model>/`
- cross-model behavior in `app/models/concerns` only when it is truly shared

The base model files are meant to read like a table of contents:

- includes
- associations
- validations
- broad scopes
- light wiring

The concept-heavy behavior moves into capability modules.

This is the repo's main architectural rule.

### 3. Integration layer

External APIs are attached to the owning domain namespace, not spread across detached coordinator objects.

Examples:

- `Product::Shopify::Parser`
- `Product::Shopify::Importer`
- `Product::Shopify::Payload`
- `Sale::Shopify::Importer`
- `Sale::Shopify::SaleItemImporter`
- `Customer::Shopify::Importer`

The lower-level HTTP / GraphQL client code stays in `app/services` when it is transport-specific rather than domain-specific.

Current examples:

- `app/services/shopify/api/client.rb`
- `app/services/shopify/graphql/*`
- `app/services/woo/edition.rb`

### 4. Async layer

Jobs are thin.

They generally own:

- queueing
- retries
- pagination / backoff transport behavior
- calling one domain entry point

They generally do not own:

- aggregate-local business rules
- payload interpretation after parsing
- inventory-linking rules
- financial logic

`Shopify::BasePullJob` is the main template for paginated imports:

```text
job fetches payload
  -> parser turns payload into normalized attributes
    -> importer updates domain records
      -> follow-up jobs continue long-running sync work
```

### 5. Presentation layer

The UI is server-rendered Rails with Hotwire.

Key pieces:

- Slim templates in `app/views`
- Turbo for incremental updates
- Stimulus controllers in `app/javascript/controllers`
- Tailwind CSS via `tailwindcss-rails`

Views are organized by resource and often by screen subtree. For example, product show and index pages are split into focused partial trees under:

- `app/views/products/show/*`
- `app/views/products/index/*`

### 6. Cross-cutting layer

Shared model concerns are reserved for behavior that truly applies across aggregates.

Important examples:

| Concern | Purpose |
| --- | --- |
| `Searchable` | shared `pg_search` setup and query entry points |
| `Shopable` | shared store lookup helpers such as `find_by_shopify_id` |
| `HasAuditNotifications` | audit-triggered background notifications |
| `HasPreviewImages` | image handling and preview variants |
| `Sanitizable` | HTML or payload sanitizing helpers used by sync flows |

---

## The Repo's Style of Rails

This app is moving toward a stronger model-first style.

The intended shape is:

- thin controllers
- rich model APIs
- narrow capability modules
- named scopes for business queries and preload shapes
- jobs that call domain code directly
- integration objects placed near the owning model when they are still part of the domain language

### What that means in practice

- If one aggregate owns the rule, put it under `app/models/<model>/...`
- If the behavior is shared across many models, use `app/models/concerns`
- If the controller or job just needs one domain action, call a named model method
- If an object is cross-aggregate or infrastructure-heavy, a separate object is fine, but it should have a clear home and purpose

### Local architecture guidance

The repo includes architecture references used by both humans and Codex under:

```text
.codex/skills/rails-domain-architecture/
```

The most important reference files are:

- `references/principles.md`
- `references/full-stack-architecture.md`
- `references/jobs-architecture.md`
- `references/testing-architecture.md`
- `references/screen-first-view-pattern.md`

Those docs describe the preferred way to place new code and refactor legacy code in this repository.

---

## Request Flow Examples

### Creating or editing a product

```text
ProductsController
  -> normalize product, edition, purchase, and media params
  -> Product#create_from_form! / #apply_form_changes!
    -> sync title and slug-related data
    -> update editions
    -> create or update store info
    -> attach media
    -> optionally create initial purchasing data
```

### Importing products from Shopify

```text
Shopify::PullProductsJob
  -> Shopify::BasePullJob
    -> Shopify::Api::Client
    -> Product::Shopify::Parser.parse
    -> Product::Shopify::Importer.import!
      -> update Product
      -> update StoreInfo
      -> enqueue edition and media follow-up jobs
```

### Importing sales from Shopify

```text
Shopify::PullSalesJob
  -> Sale::Shopify::Parser.parse
  -> Sale::Shopify::Importer.import!
    -> update Sale
    -> update Sale store info
    -> import SaleItems
    -> link with PurchaseItems when status allows
    -> notify customers about order-location changes when needed
```

### Moving inventory between warehouses

```text
purchase item move request
  -> controller loads target items and warehouse inputs
  -> warehousing behavior on PurchaseItem / Warehouse
  -> WarehouseTransition records movement rules
  -> customer notifications may be triggered for affected orders
```

---

## Important Subsystems

### Catalog and variants

Catalog data starts from `Franchise` and `Product`.

`Product` owns:

- title and full-title composition
- edition generation
- store references
- media coordination
- high-level listing and sales-history queries

`Edition` represents a concrete sellable option combination and supports both:

- simple base-model products
- richer variant combinations through size, version, and color

### Purchasing and financials

Purchasing is centered around:

- `Supplier`
- `Purchase`
- `Payment`
- `PurchaseItem`

This area tracks:

- quantity and item price
- per-purchase and per-item financial totals
- supplier debt reduction through payments
- purchase-to-sale linking

### Warehousing

Inventory is stored at the per-unit level through `PurchaseItem`.

This gives the app fine-grained control over:

- physical location
- warehouse movement
- shipping metadata
- order allocation

`WarehouseTransition` stores the allowed or tracked movement relationships between warehouses.

### Store sync

The app currently integrates with:

- Shopify
- WooCommerce

`StoreInfo` is the shared store metadata layer. It lets the domain models keep store-specific identifiers, sync times, slugs, and checksums without hard-coding those columns onto every aggregate.

---

## Code Organization

### Top-level app layout

```text
app/
  controllers/   request boundary
  jobs/          async transport shells
  models/        domain layer
  policies/      Pundit authorization
  services/      transport or API adapters
  views/         Slim + Turbo UI
  javascript/    Stimulus controllers
```

### Models layout

The repository uses a namespaced model layout rather than putting all behavior into giant base files.

Typical pattern:

```text
app/models/product.rb
app/models/product/editing.rb
app/models/product/listing.rb
app/models/product/titling.rb
app/models/product/shopify/importer.rb
```

This is the preferred direction for new domain work.

### Views layout

Views are mostly screen-oriented and resource-oriented.

Examples:

- `app/views/products/index/*`
- `app/views/products/show/*`
- `app/views/sales/items/*`
- `app/views/purchases/form/*`

This keeps large screens readable without pushing presentation logic into models.

### Where to put new code

| If the change is... | Put it here first | Notes |
| --- | --- | --- |
| behavior owned by one aggregate | `app/models/<model>/<capability>.rb` | Default choice for domain rules, commands, callbacks, and aggregate-local scopes. |
| a larger workflow still owned by one aggregate | `app/models/<model>/<workflow>.rb` | Good for imports, reconciliation, or multi-step domain operations that still belong to one model area. |
| shared cross-model behavior | `app/models/concerns/<concern>.rb` | Use only when the behavior is truly shared and not just extracted for file size. |
| a repeated business query or preload shape | named scope on the owning model | Prefer relation-returning scopes over controller SQL or tiny query wrappers. |
| request setup, params normalization, response format | controller or controller concern | Keep domain branching and transactions out of the controller. |
| async transport, retry, scheduling, pagination | `app/jobs/...` | Jobs should call one clear domain entry point. |
| store API transport or GraphQL client code | `app/services/shopify/...` or another explicit adapter namespace | Keep low-level transport concerns separate from domain ownership. |
| parser, importer, payload builder tied to one aggregate | `app/models/<model>/<integration>/...` | Keep integration-specific domain translation near the owning aggregate. |
| screen-only rendering logic | helper, partial, Turbo template, or view subtree | Do not move screen wording or screen branching into models by default. |
| cross-aggregate orchestration or infrastructure-heavy coordination | explicit namespace under `app/models/<namespace>/` or another clear boundary | Reach for this only when a direct model API would be unnatural. |

### Naming bias

Prefer names that sound like the business domain:

- `publish`
- `move_to`
- `link_purchase_items`
- `sync_store_references`

Avoid generic or UI-shaped names when a domain verb exists:

- `process_form`
- `handle_update`
- `run_service`
- `manager`

---

## Authentication and Authorization

### Authentication

The app uses custom session-based authentication:

- `Current` stores the current session
- `Current.user` is delegated from the session
- signed cookies hold `session_id`
- `User` uses `has_secure_password`

Unauthenticated requests are redirected to the sign-in flow.

### Authorization

Authorization is handled with Pundit.

The authorization concern runs on controllers automatically and verifies that each request is authorized.

Current roles are:

- `admin`
- `manager`
- `support`
- `guest`

---

## Testing Strategy

The test suite is RSpec-based and mirrors ownership seams in the app.

### Main test layers

- `spec/models` for domain behavior and capability modules
- `spec/requests` and selected controller specs for request boundaries
- `spec/jobs` for async transport behavior
- `spec/features` for high-risk browser flows
- `spec/policies` for authorization rules
- `spec/integration` for cross-boundary sync behavior

### What is emphasized

- domain behavior close to the owning model
- end-to-end inventory and sales flows
- integration parsing and import behavior
- background job retries and sync pagination
- policy coverage for role-sensitive screens

### Representative flows covered

- sale to purchase-item linking
- store sync for products and sales
- warehouse movement
- product editions and media handling
- debt tracking and purchase flows

---

## Observability and Operations

### Monitoring

- Sentry for error tracking
- Scout APM in production
- Sidekiq Web at `/jobs`
- PgHero in development
- Prosopite in development for N+1 detection

### Data integrity

- PostgreSQL foreign keys
- `database_validations`
- `audited`
- counter caches where needed

### Async runtime

- Active Job on Sidekiq
- Redis-backed job processing
- retry on deadlocks at the application job level

---

## Tech Stack

| Category | Technology |
| --- | --- |
| Language | Ruby 4.0.1 |
| Framework | Rails 8.x |
| Database | PostgreSQL |
| Search | `pg_search` |
| Jobs | Sidekiq + `sidekiq-status` |
| Auth | custom sessions + `bcrypt` |
| Authorization | Pundit |
| UI | Hotwire, Stimulus, Slim, Tailwind CSS |
| Storage | Active Storage, S3-compatible object storage |
| Integrations | Shopify, WooCommerce |
| Testing | RSpec, FactoryBot, Capybara, Cuprite, Shoulda Matchers |

---

## Running Locally

### Requirements

- Ruby 4.0.1
- PostgreSQL
- Redis

### Setup

```bash
bundle install
bin/rails db:create db:migrate
```

### Run the app

```bash
bin/dev
```

`bin/dev` starts:

- Rails web server on port `3000`
- Sidekiq worker
- Tailwind watcher

### Run tests

```bash
bin/rspec
```

Parallel example:

```bash
PARALLEL_TEST_PROCESSORS=6 bin/rspec
```

---

## How to Approach Changes in This Repo

When adding or refactoring code, the safest default is:

1. identify the owning aggregate
2. keep the controller or job thin
3. add behavior under `app/models/<model>/...`
4. reserve `app/models/concerns` for truly shared behavior
5. add tests at the same ownership seam

If the app feels inconsistent in places, treat the current file placement as evidence rather than architecture to preserve blindly. The preferred direction is the model-centric shape described above.

---

## License

Personal project. Code is open for reference.
