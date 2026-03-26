# Store Manager v2

Store Manager v2 is a Rails 8 monolith for running collectible inventory operations across purchasing, warehousing, sales, and store sync.

At a high level, the app answers one business question end to end:

When a customer buys a product, which physical item fulfilled the order, where did it come from, what does it still cost us, and where is it now?

This repository is intentionally model-centric. Most business behavior lives in `app/models`, controllers stay thin, jobs mainly move work around, and store integrations stay close to the part of the business they support instead of drifting into a generic service layer.

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
  Shopify / Woo payload -> Parser -> Importer -> local records
```

### The main business promise

The app tries to keep the sellable view and the physical view connected:

- `Product` and `Edition` describe what we sell
- `Sale` and `SaleItem` describe what customers ordered
- `Purchase` and `PurchaseItem` describe what we actually bought
- `Warehouse` and `WarehouseTransition` describe where inventory lives and how it moves

That lets us answer financial, logistics, and customer-service questions from one system instead of stitching together spreadsheets and store dashboards.

---

## Business Record Map

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

### Core business records

| Record | Responsibility |
| --- | --- |
| `Product` | Catalog root. Owns title composition, edition generation, store references, media coordination, and sales history views. |
| `Edition` | Concrete sellable variant built from product option dimensions such as size, version, and color. |
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

## How the App Is Organized

### 1. User actions and controllers

Controllers handle incoming user actions.

They are responsible for:

- loading the starting record or relation
- normalizing params
- choosing response format
- redirecting or rendering

They are not meant to be the main home for business rules.

A representative example is `ProductsController`, which uses small form-translation objects such as `Product::FormPayload` and `Product::FormRehydrator` before calling model methods such as `create_from_form!` and `apply_form_changes!`.

The rule in this repo is:

- small params normalization may stay in the controller
- once a form needs several normalization helpers or failed-submit rebuilding, extract a small object near the business area it belongs to

Typical examples:

- `app/models/product/form_payload.rb`
- `app/models/product/form_rehydrator.rb`
- `app/models/purchase/form_payload.rb`

These are not generic service objects. They are small translators for one specific business form.

### 2. Business rules and model areas

Most business rules live in `app/models`.

Each important business area usually has:

- a short base model file that acts like a table of contents
- supporting files under `app/models/<model>/`
- shared behavior in `app/models/concerns` only when it is truly shared

The base model files are meant to read like a table of contents:

- includes
- associations
- validations
- broad scopes
- light wiring

The heavier business logic moves into nearby supporting files.

This is the repo's main architectural rule.

### 3. Store sync and external APIs

Store-specific logic stays close to the business area it updates, instead of being spread across detached coordinator objects.

Examples:

- `Product::Shopify::Parser`
- `Product::Shopify::Importer`
- `Product::Shopify::Payload`
- `Sale::Shopify::Importer`
- `Sale::Shopify::SaleItemImporter`
- `Customer::Shopify::Importer`

The lower-level HTTP or GraphQL client code stays in `app/services` when it is mainly about talking to an external API.

Current examples:

- `app/services/shopify/api/client.rb`
- `app/services/shopify/graphql/*`
- `app/services/woo/edition.rb`

### 4. Background jobs

Jobs are thin.

They generally own:

- queueing
- retries
- pagination or backoff behavior
- calling one clear model method or importer

They generally do not own:

- business rules for one area of the app
- payload interpretation after parsing
- inventory-linking rules
- financial logic

`Shopify::BasePullJob` is the main template for paginated imports:

```text
job fetches payload
  -> parser turns payload into normalized attributes
    -> importer updates local records
      -> follow-up jobs continue long-running sync work
```

### 5. Screens and interactions

The UI is server-rendered Rails with Hotwire.

Key pieces:

- Slim templates in `app/views`
- Turbo for incremental updates
- Stimulus controllers in `app/javascript/controllers`
- Tailwind CSS via `tailwindcss-rails`

The UI rules are:

- let the server render the initial structure and prepared view data
- organize views by resource and then by screen subtree when a page gets large
- keep screen-only wording, branching, and small view-data shaping at the edge in helpers, partials, and Turbo templates
- keep Stimulus focused on interaction state, DOM toggles, and loading transitions for one widget

One practical rule matters a lot here: UI tests are part of the design.

Because the application uses Stimulus, CSS state, and server-rendered HTML together, risky UI work should usually include a focused browser-level feature spec. That is how we lock in behavior the code alone cannot guarantee, such as:

- loading skeletons appearing and disappearing at the right time
- dialog open and close behavior
- image or gallery state transitions
- geometry staying stable while assets load

### 6. Shared building blocks

Shared model concerns are reserved for behavior that truly applies across several business areas.

Important examples:

| Concern | Purpose |
| --- | --- |
| `Searchable` | shared `pg_search` setup and search helpers |
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
- small supporting files near each model
- small form-translation objects when request-shape translation grows
- named scopes for business queries and common loading patterns
- jobs that call domain code directly
- integration objects placed near the owning model when they are still part of the business workflow

### What that means in practice

The architectural layers above are the main explanation. In day-to-day work, the practical defaults are:

- If one business area owns the rule, put it under `app/models/<model>/...`
- If the behavior is shared across many models, use `app/models/concerns`
- If the controller or job just needs one business action, call a named model method
- If one widget or partial needs small screen-only view-data shaping, prefer a helper over a presenter
- If an object coordinates several business areas or is infrastructure-heavy, a separate object is fine, but it should have a clear home and purpose

### How this differs from a layered `forms / presenters / queries / services` layout

Many Rails codebases organize application logic by technical role:

- `app/forms`
- `app/presenters`
- `app/queries`
- `app/searchers`
- `app/services`

That style can work well, but it is not the main organizing principle in this repo.

Here, the default question is not "what kind of object is this?" but "which business concept is responsible for this rule?"

### Quick comparison

| Dimension | Layered Rails (`forms / presenters / queries / services`) | Classic DDD | This repo |
| --- | --- | --- | --- |
| Primary organizing principle | Technical role | Business model with stronger separation between business rules and technical layers | Business ownership inside one Rails monolith |
| Main question when placing code | "What kind of object is this?" | "Which business area or business object owns this?" | "Which business concept is responsible for this rule?" |
| Default home for business logic | Often spread across services, forms, queries | Business objects and dedicated business services | `app/models/<model>/...` supporting files and nearby model objects |
| Controllers | Often coordinate multiple service and form objects | Thin application layer adapters | Thin request handlers that call model methods |
| Queries | Often separate query objects by default | Dedicated repositories or read models are more common | Named scopes and model-area query methods first, standalone query objects only when the query becomes big enough to deserve its own home |
| Presentation shaping | Presenters or decorators are common | Separate application or interface layer | Helpers, partials, Turbo templates; presenters are not the default |
| Integrations | Frequently coordinated in top-level services | Usually separated behind clear business and application boundaries | Business-specific parsers and importers live near the owning model; API clients stay in `app/services` |
| Strength | Clear technical buckets | Very explicit modeling and boundaries | Fast feature tracing, strong business ownership, practical Rails ergonomics |
| Main risk | One feature gets scattered across many folders | Can become heavy or over-abstract for a monolith | Requires discipline so model folders stay coherent and do not become catch-all buckets |

The practical advantage of this repo's style is that most changes stay close to the part of the business that makes the decision.

That usually makes it easier to understand a feature end to end:

- the controller shows where the user action enters the system
- the model area shows the business behavior
- the helper or partial shows the screen-only shaping
- the job or integration object shows sync, API, or background-work edges

This gives us some of the clarity people want from DDD without paying the full ceremony cost of strict DDD layers inside a Rails monolith.

That leads to a different placement strategy:

- business behavior owned by one model area lives under `app/models/<model>/...`
- complex form translation stays near the owning business concept as objects such as `Product::FormPayload`
- business queries usually stay as named scopes or model-area query methods before becoming standalone query objects
- screen-only presentation shaping usually stays in helpers and partials before becoming presenters
- `app/services` is reserved mostly for infrastructure concerns such as API clients and GraphQL wrappers

In other words, this repo is organized primarily by business ownership and only secondarily by technical role.

The tradeoff is intentional:

- we give up some "all forms live together" or "all queries live together" symmetry
- in return, most feature work stays close to the business area that owns the rule, which makes request flows, async jobs, and integrations easier to trace end to end

This is why you will find files such as:

- [`app/models/product/form_payload.rb`](app/models/product/form_payload.rb)
- [`app/models/product/form_rehydrator.rb`](app/models/product/form_rehydrator.rb)
- [`app/models/product/shopify/importer.rb`](app/models/product/shopify/importer.rb)
- [`app/models/sale/statuses.rb`](app/models/sale/statuses.rb)
- [`app/models/purchase/linking.rb`](app/models/purchase/linking.rb)

instead of a broad top-level split across `app/forms`, `app/importers`, `app/queries`, and `app/services`.

For the detailed placement guide, see `Where to put new code` below.

### Local architecture guidance

The repo includes architecture references used by both humans and Codex under:

```text
.codex/skills/rails-domain-architecture/
```

The most important reference files are:

- [`references/principles.md`](.codex/skills/rails-domain-architecture/references/principles.md)
- [`references/full-stack-architecture.md`](.codex/skills/rails-domain-architecture/references/full-stack-architecture.md)
- [`references/jobs-architecture.md`](.codex/skills/rails-domain-architecture/references/jobs-architecture.md)
- [`references/testing-architecture.md`](.codex/skills/rails-domain-architecture/references/testing-architecture.md)
- [`references/screen-first-view-pattern.md`](.codex/skills/rails-domain-architecture/references/screen-first-view-pattern.md)

Those docs describe the preferred way to place new code and refactor older parts of the app in this repository.

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

## Important Business Areas

### Catalog and variants

Catalog data starts from [`Franchise`](app/models/franchise.rb) and [`Product`](app/models/product.rb).

`Product` owns the core catalog workflows:

- title and full-title composition
- edition generation
- store references
- media coordination
- high-level listing and sales-history queries

[`Edition`](app/models/edition.rb) represents a concrete sellable option combination and supports both:

- simple base-model products
- richer variant combinations through size, version, and color

### Purchasing and financials

Purchasing is centered around:

- [`Supplier`](app/models/supplier.rb)
- [`Purchase`](app/models/purchase.rb)
- [`Payment`](app/models/payment.rb)
- [`PurchaseItem`](app/models/purchase_item.rb)

This area tracks:

- quantity and item price
- per-purchase and per-item financial totals
- supplier debt reduction through payments
- purchase-to-sale linking

### Warehousing

Inventory is stored at the per-unit level through [`PurchaseItem`](app/models/purchase_item.rb).

This gives the app fine-grained control over:

- physical location
- warehouse movement
- shipping metadata
- order allocation

[`WarehouseTransition`](app/models/warehouse_transition.rb) stores the allowed or tracked movement relationships between warehouses.

### Store sync

The app currently integrates with:

- Shopify
- WooCommerce

[`StoreInfo`](app/models/store_info.rb) is the shared store metadata layer. It lets the business models keep store-specific identifiers, sync times, slugs, and checksums without hard-coding those columns onto every main record.

---

## Code Organization

### Top-level app layout

```text
app/
  controllers/   user actions and responses
  jobs/          background work
  models/        business rules and records
  policies/      Pundit authorization
  services/      API and infrastructure adapters
  views/         Slim + Turbo UI
  javascript/    Stimulus controllers
```

### Models layout

The repository uses grouped model folders rather than putting all behavior into giant base files.

Typical pattern:

```text
app/models/product.rb
app/models/product/editing.rb
app/models/product/listing.rb
app/models/product/titling.rb
app/models/product/shopify/importer.rb
```

This is the preferred direction for new business logic.

### Views layout

Views are mostly resource-oriented first, then screen-oriented inside each resource.

The common shape is:

```text
app/views/<resource>/
  index.html.slim
  show.html.slim
  form/_form.html.slim
  index/*
  show/*
  turbo_stream/*
```

When a screen grows, split it by screen subtree rather than pushing presentation logic into models or inventing presenter layers.

Examples:

- `app/views/products/index/*`
- `app/views/products/show/*`
- `app/views/sales/items/*`
- `app/views/purchases/form/*`

Helpers are the default place for small screen-only preparation. Use them for mechanical view shaping that belongs to one widget, partial tree, or response format.

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
| screen-only rendering logic | helper, partial, Turbo template, or view subtree | Do not move screen wording or screen branching into models by default. |
| small screen-only view-data shaping for one partial or widget | helper | Prefer a helper over a presenter; keep it mechanical and presentation-only. |
| coordination across several business areas or infrastructure-heavy logic | explicit folder under `app/models/<name>/` or another clear boundary | Reach for this only when a direct model API would be unnatural. |

### Naming bias

Prefer names that sound like the business:

- `publish`
- `move_to`
- `link_purchase_items`
- `sync_store_references`

Avoid generic or UI-shaped names when a business verb exists:

- `process_form`
- `handle_update`
- `run_service`
- `manager`

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

Authorization is handled with Pundit.

The [authorization concern](app/controllers/concerns/authorization.rb) runs on controllers automatically and verifies that each request is authorized.

Current roles are:

- `admin`
- `manager`
- `support`
- `guest`

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

Helpful examples in this repo:

- [`spec/models/product`](spec/models/product)
- [`spec/jobs`](spec/jobs)
- [`spec/features`](spec/features)
- [`spec/policies`](spec/policies)

### What is emphasized

- business behavior close to the owning model
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
mise exec -- bin/bundle install
mise exec -- bin/rails db:create db:migrate
```

### Run the app

```bash
mise exec -- bin/dev
```

`bin/dev` starts:

- Rails web server on port `3000`
- Sidekiq worker
- Tailwind watcher

### Run tests

```bash
mise exec -- bin/rspec
```

Parallel example:

```bash
PARALLEL_TEST_PROCESSORS=6 mise exec -- bin/rspec
```

---

## How to Approach Changes in This Repo

When adding or refactoring code, a quick working checklist is:

1. identify which business area is responsible for the rule
2. choose whether you are changing user flow, business behavior, or screen rendering
3. use `Where to put new code` for the default file placement
4. keep the edges thin and the ownership clear
5. add tests at the same level as the behavior

If the app feels inconsistent in places, treat current file placement as evidence rather than architecture to preserve blindly. Use the architecture sections above for the reasoning, and `Where to put new code` for the practical default.

---

## License

Personal project. Code is open for reference.
