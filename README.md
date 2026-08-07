# Store Manager v2

Store Manager v2 is a Rails 8 monolith for running collectible inventory operations across purchasing, warehousing, sales, and store sync.

At a high level, the app answers one business question end to end:

When a customer buys a product, which physical item fulfilled the order, where did it come from, what does it still cost us, and where is it now?

This repository is intentionally model-centric. Most business behavior lives in `app/models`, controllers stay thin, jobs mainly move work around, and store integrations stay close to the part of the business they support instead of drifting into a generic service layer.

## Contents

- [Bird's-Eye View](#birds-eye-view) - what the system manages and the main business flow
- [Architecture](#architecture) - the model-first approach and how it differs from layered Rails
- [How the App Is Organized](#how-the-app-is-organized) - controllers, models, integrations, jobs, and UI
- [Business Record Map](#business-record-map) - the core records and what they own
- [Request Flow Examples](#request-flow-examples) - concrete product, sale, and inventory flows
- [Important Business Areas](#important-business-areas) - catalog, purchasing, warehousing, and store sync
- [Code Organization](#code-organization) - app layout and where to put new code
- [Authentication and Authorization](#authentication-and-authorization)
- [Testing Strategy](#testing-strategy)
- [Observability and Operations](#observability-and-operations)
- [Tech Stack](#tech-stack)
- [Running Locally](#running-locally)
- [How to Approach Changes in This Repo](#how-to-approach-changes-in-this-repo)
- [License](#license)

---

## Bird's-Eye View

### What the system manages

- product catalog for collectible goods
- variant modeling through variants, sizes, versions, and colors
- supplier purchases and partial payments
- per-unit inventory via `PurchaseItem`
- warehouse storage and warehouse-to-warehouse transitions
- customer sales from Shopify and WooCommerce
- linking sold line items to physical inventory
- store metadata and sync timestamps through `StoreInfo`

### Core business flow

```text
Catalog setup
  Franchise -> Product -> Variant

Inventory acquisition
  Supplier -> Purchase -> PurchaseItem -> Warehouse

Sales fulfillment
  Customer -> Sale -> SaleItem -> PurchaseItem

External sync
  Shopify / Woo payload -> Parser -> Importer -> local records
```

### The main business promise

The app keeps the sellable view and the physical view connected, so financial, logistics, and customer-service questions can be answered from one system instead of stitched-together spreadsheets and store dashboards:

- `Product` and `Variant` describe what we sell
- `Sale` and `SaleItem` describe what customers ordered
- `Purchase` and `PurchaseItem` describe what we actually bought
- `Warehouse` and `WarehouseTransition` describe where inventory lives and how it moves

## Architecture

This app uses a model-first architecture:

- thin controllers
- rich model APIs
- small supporting files near each model
- small form-translation objects when request-shape translation grows
- named scopes for business queries and common loading patterns
- jobs that call domain code directly
- integration objects placed near the owning model when they are still part of the business workflow

### What that means in practice

- If one business area owns the rule, put it under `app/models/<model>/...`
- If the behavior is shared across many models, use `app/models/concerns`
- If the controller or job just needs one business action, call a named model method
- If one widget or partial needs small screen-only view-data shaping, prefer a helper over a presenter
- If an object coordinates several business areas or is infrastructure-heavy, a separate object is fine, but it should have a clear home and purpose

### How this differs from a layered `forms / presenters / queries / services` layout

Many Rails codebases organize logic by technical role (`app/forms`, `app/presenters`, `app/queries`, `app/searchers`, `app/services`). That style works, but it is not the main organizing principle here. The default question is not "what kind of object is this?" but "which business concept is responsible for this rule?"

| Decision lens | Layered Rails (`forms / presenters / queries / services`) | This repo |
| --- | --- | --- |
| Main organizing question | "What kind of object is this?" | "Which business concept is responsible for this rule?" |
| How business rules are usually grouped | Split by object type such as form, query, presenter, or service | Grouped near the business area that owns the rule |
| How screen logic is usually grouped | Often in presenters, decorators, or screen-focused service objects | Usually kept in Inertia page props, React page components, and small helpers |
| How external integrations are usually grouped | Often coordinated by top-level services | Parsers and importers live near the business area they update; low-level API clients stay in `app/services` |
| What becomes easier | Finding all objects of the same technical kind | Tracing one feature end to end |
| What becomes harder | Understanding one business feature across many folders | Keeping model folders focused and not turning them into catch-all buckets |

This repo borrows the business-ownership idea from DDD but expresses it in plain Rails terms — scopes, helpers, and nearby model files come before repositories, application services, or separate domain-layer objects. So you will see files such as:

- [`app/models/product/editing.rb`](app/models/product/editing.rb)
- [`app/models/product/editing/payload.rb`](app/models/product/editing/payload.rb)
- [`app/models/product/shopify/importer.rb`](app/models/product/shopify/importer.rb)
- [`app/models/sale/statuses.rb`](app/models/sale/statuses.rb)
- [`app/models/purchase/linking.rb`](app/models/purchase/linking.rb)

instead of a broad top-level split across `app/forms`, `app/importers`, `app/queries`, and `app/services`. For file-placement defaults, see [Where to put new code](#where-to-put-new-code).

### Local architecture guidance

Detailed, task-specific guidance lives in [`AGENTS.md`](AGENTS.md) and the skill files it points to:

- `rails-domain-architecture/SKILL.md` — backend, model-centric design
- `frontend-architecture/SKILL.md` — Inertia + React UI work
- `inline-cell-editor/SKILL.md` — adding or changing inline table-cell editors

These live in `.agents/skills/`; `.claude/skills/` and `.codex/skills/` are symlinks to that canonical directory.

---

## How the App Is Organized

### 1. User actions and controllers

Controllers load the starting record or relation, normalize params, choose a response format, and render or redirect. They are not the main home for business rules.

`ProductsController` is representative: it builds a small form-translation object (`Product::Editing::Payload`) and hands its attributes to a model method (`Product#save_editing!`). Small params normalization may stay in the controller; once a form needs several normalization helpers or failed-submit rebuilding, extract a small object near the business area it belongs to (e.g. `app/models/product/editing/payload.rb`, `app/models/purchase/form_payload.rb`). These are translators for one specific business form, not generic service objects.

### 2. Business rules and model areas

Most business rules live in `app/models`. Each important business area usually has a short base model file that reads like a table of contents (includes, associations, validations, broad scopes, light wiring), with heavier logic moved into supporting files under `app/models/<model>/`. Shared behavior goes in `app/models/concerns` only when it is truly shared. This is the repo's main architectural rule.

### 3. Store sync and external APIs

Store-specific translation stays close to the business area it updates rather than in detached coordinators:

- `Product::Shopify::Parser`, `Product::Shopify::Importer`, `Product::Shopify::Payload`
- `Sale::Shopify::Importer`, `Sale::Shopify::SaleItemImporter`
- `Customer::Shopify::Importer`

Lower-level HTTP or GraphQL client code stays in `app/services` when it is mainly about talking to an external API — `app/services/shopify/api/client.rb`, `app/services/shopify/graphql/*`, `app/services/woo/variant.rb`.

### 4. Background jobs

Jobs are thin. They own queueing, retries, pagination/backoff, and calling one clear model method or importer. They do not own business rules, payload interpretation after parsing, inventory-linking, or financial logic.

`Shopify::BasePullJob` is the template for paginated imports:

```text
job fetches payload
  -> parser turns payload into normalized attributes
    -> importer updates local records
      -> follow-up jobs continue long-running sync work
```

### 5. Screens and interactions

The UI runs through `inertia_rails`: Rails controllers render Inertia pages and React owns the browser-side screen tree.

- Rails controllers call `render inertia: "...", props: ...`
- React pages, layouts, components, and tests live in `app/frontend`
- `@inertiajs/react` owns links, forms, visits, shared page props, and client-side navigation
- Vite Ruby builds the frontend entrypoints, including Inertia SSR; Tailwind CSS compiles through the Vite Tailwind plugin

The division of labor: let Rails load records, authorize requests, and prepare page props (usually in helpers and focused prop builders); keep screen wording, branching, and view-data shaping at the Inertia boundary; organize React pages by resource under `app/frontend/pages`, splitting large screens into local components and hooks; reuse shared components from `app/frontend/components`; and use generated `js-from-routes` helpers from `app/frontend/api` instead of hand-written path strings.

UI tests are part of the design, not a polish step. Because screens combine Rails-prepared props, Inertia navigation, React state, and CSS, risky UI work should include focused component or browser-level coverage for things the code alone cannot guarantee — Inertia form submissions and validation errors, client-side navigation and shared layout behavior, dialog open/close, image/gallery state transitions, and geometry staying stable while assets load.

### 6. Shared building blocks

Shared model concerns are reserved for behavior that truly applies across several business areas:

| Concern | Purpose |
| --- | --- |
| `Searchable` | shared `pg_search` setup and search helpers |
| `Shopable` | shared store lookup helpers such as `find_by_shopify_id` |
| `HasAuditNotifications` | audit-triggered background notifications |
| `HasPreviewImages` | image handling and preview variants |
| `Sanitizable` | HTML or payload sanitizing helpers used by sync flows |

---

## Business Record Map

```text
Franchise
  -> Product
    -> Variant
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

### Core business records

| Record | Responsibility |
| --- | --- |
| `Product` | Catalog root. Owns title composition, variant generation, store references, media coordination, and sales history views. |
| `Variant` | Concrete sellable variant built from product option dimensions such as size, version, and color. |
| `Purchase` | Supplier-facing order with cost, quantity, payments, and inventory-linking rules. |
| `PurchaseItem` | One physical inventory unit with warehousing, shipping, notification, and sale-linking behavior. |
| `Sale` | Customer-facing order imported from stores, with status calculation and inventory-linking actions. |
| `SaleItem` | One sold line item that can be matched to one or more `PurchaseItem` records. |
| `StoreInfo` | Polymorphic store metadata layer for Shopify and Woo records, IDs, timestamps, and sync checksums. |
| `Warehouse` | Physical storage location plus movement rules, listing, lifecycle behavior, and transitions. |

### Examples of where business behavior lives

```text
app/models/product/
  editing.rb
  variant_generation.rb
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

## Request Flow Examples

### Creating or editing a product

```text
ProductsController
  -> Product::Editing::Payload normalizes product, variant, store-info, purchase, and media params
  -> Product#save_editing!
    -> assign product, variant, and store-info attributes
    -> sync variant options and ensure SKUs
    -> validate, then save in a transaction
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
      -> enqueue variant and media follow-up jobs
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

## Important Business Areas

See [Core business records](#core-business-records) for what each record owns. Entry points by area:

- **Catalog and variants** — [`Franchise`](app/models/franchise.rb), [`Product`](app/models/product.rb), [`Variant`](app/models/variant.rb). `Product` owns title composition, variant generation, store references, media coordination, and listing/sales-history queries; `Variant` covers both simple base-model products and richer size/version/color combinations.
- **Purchasing and financials** — [`Supplier`](app/models/supplier.rb), [`Purchase`](app/models/purchase.rb), [`Payment`](app/models/payment.rb), [`PurchaseItem`](app/models/purchase_item.rb). Tracks quantity and item price, per-purchase and per-item totals, supplier debt reduction through payments, and purchase-to-sale linking.
- **Warehousing** — inventory is stored per-unit on [`PurchaseItem`](app/models/purchase_item.rb) (physical location, movement, shipping metadata, order allocation); [`WarehouseTransition`](app/models/warehouse_transition.rb) stores the allowed or tracked movement relationships between warehouses.
- **Store sync** — integrates with Shopify and WooCommerce. [`StoreInfo`](app/models/store_info.rb) is the shared metadata layer holding store identifiers, sync times, slugs, and checksums without hard-coding those columns onto every record.

---

## Code Organization

### Top-level app layout

```text
app/
  controllers/   user actions and responses
  frontend/      Inertia React pages, layouts, components, API route helpers, and entrypoints
  jobs/          background work
  models/        business rules and records
  policies/      Pundit authorization
  services/      API and infrastructure adapters
  views/         Rails layout shell for Inertia
```

### Models layout

```text
app/models/product.rb
app/models/product/editing.rb
app/models/product/listing.rb
app/models/product/titling.rb
app/models/product/shopify/importer.rb
```

### Frontend layout

Inertia pages are resource-oriented first, then screen-oriented inside each resource:

```text
app/frontend/
  entrypoints/       Vite entrypoints for Inertia and SSR
  layouts/           shared page layouts
  pages/<resource>/  Inertia page components and local screen pieces
  components/        shared React components
  api/               generated js-from-routes helpers
  types/             shared frontend types
```

Examples: `app/frontend/pages/Products/*`, `app/frontend/pages/Purchases/Show/*`, `app/frontend/pages/Sales/Show/*`, `app/frontend/components/*`. Helpers remain the default place for small server-side page-prop preparation.

### Where to put new code

| If the change is... | Put it here first | Notes |
| --- | --- | --- |
| behavior owned by one business area | `app/models/<model>/<feature>.rb` | Default choice for business rules, commands, callbacks, and local scopes. |
| a larger workflow still owned by one business area | `app/models/<model>/<workflow>.rb` | Good for imports, reconciliation, or multi-step work that still belongs to one model area. |
| shared cross-model behavior | `app/models/concerns/<shared_behavior>.rb` | Use only when the behavior is truly shared and not just extracted for file size. |
| a repeated business query or common loading shape | named scope on the owning model | Prefer scopes over controller SQL or tiny query wrappers. |
| request setup, params normalization, response format | controller or controller concern | Keep business branching and transactions out of the controller. |
| background retries, scheduling, pagination | `app/jobs/...` | Jobs should call one clear model method or importer. |
| store API or GraphQL client code | `app/services/shopify/...` or another explicit integration folder | Keep low-level API code separate from business behavior. |
| parser, importer, payload builder tied to one business area | `app/models/<model>/<integration>/...` | Keep store-specific translation near the business area it updates. |
| screen-only rendering logic | Inertia page component, local React component or hook, or focused helper | Do not move screen wording or screen branching into models by default. |
| small screen-only view-data shaping for one page or widget | helper or focused page-prop builder | Prefer simple edge code over a presenter; keep it mechanical and presentation-only. |
| coordination across several business areas or infrastructure-heavy logic | explicit folder under `app/models/<name>/` or another clear boundary | Reach for this only when a direct model API would be unnatural. |

### Naming bias

Prefer names that sound like the business (`publish`, `move_to`, `link_purchase_items`, `sync_store_references`) over generic or UI-shaped names (`process_form`, `handle_update`, `run_service`, `manager`).

---

## Authentication and Authorization

### Authentication

The app uses custom session-based authentication:

- [`Current`](app/models/current.rb) stores the current session
- `Current.user` is delegated from the session
- signed cookies hold `session_id`
- [`User`](app/models/user.rb) uses `has_secure_password`

Unauthenticated requests are redirected to the sign-in flow.

### Authorization

Authorization is handled with Pundit. The [authorization concern](app/controllers/concerns/authorization.rb) runs on controllers automatically and verifies that each request is authorized. Current roles are `admin`, `manager`, `support`, and `guest`.

---

## Testing Strategy

The test suite is RSpec-based and mirrors the main responsibility lines in the app.

### Main test layers

- `spec/models` for business behavior and model-area files
- `spec/requests` and selected controller specs for request handling
- `spec/jobs` for background-work behavior
- `spec/features` for high-risk browser flows
- `spec/policies` for authorization rules
- `spec/integration` for cross-boundary sync behavior

Examples: [`spec/models/product`](spec/models/product), [`spec/jobs`](spec/jobs), [`spec/features`](spec/features), [`spec/policies`](spec/policies).

### Representative flows covered

- sale to purchase-item linking
- store sync for products and sales
- warehouse movement
- product variants and media handling
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
| Language | Ruby 4.0.5 |
| Framework | Rails 8.x |
| Database | PostgreSQL |
| Search | `pg_search` |
| Jobs | Sidekiq + `sidekiq-status` |
| Auth | custom sessions + `bcrypt` |
| Authorization | Pundit |
| UI | Inertia Rails, React, Vite Ruby, Tailwind CSS |
| Storage | Active Storage, S3-compatible object storage |
| Integrations | Shopify, WooCommerce |
| Testing | RSpec, FactoryBot, Capybara, Cuprite, Shoulda Matchers |

---

## Running Locally

### Requirements

- Ruby 4.0.5 and Node 24, pinned in `mise.toml`
- PostgreSQL
- Redis

### Setup

```bash
mise exec -- bin/bundle install
mise exec -- bin/rails db:create db:migrate
```

### Run the app

```bash
mise exec -- bin/dev
```

`bin/dev` starts the Rails web server on port `3000`, a Sidekiq worker, and the Vite dev server for React, Inertia, and Tailwind assets.

### Run tests

```bash
mise exec -- bin/rspec
```

Parallel example:

```bash
PARALLEL_TEST_PROCESSORS=6 mise exec -- bin/parallel-rspec
```

---

## How to Approach Changes in This Repo

When adding or refactoring code:

1. identify which business area is responsible for the rule
2. choose whether you are changing user flow, business behavior, or screen rendering
3. use [Where to put new code](#where-to-put-new-code) for the default file placement
4. keep the edges thin and the ownership clear
5. add tests at the same level as the behavior

If the app feels inconsistent in places, treat current file placement as evidence rather than architecture to preserve blindly.

---

## License

Personal project. Code is open for reference.
