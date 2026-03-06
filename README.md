# Store Manager v2 — Inventory ERP Platform

A production Rails 8 monolith for multi-channel e-commerce inventory and financial operations.

**Core domain:** Track collectible inventory from supplier purchase through warehouse storage to multi-channel sales (Shopify + WooCommerce), with full financial tracking including supplier debt, payment schedules, and inventory allocation.

---

## Domain Overview

### The Business Problem

When a customer orders a product on Shopify or WooCommerce:
1. Which physical inventory unit fulfills their order?
2. Which supplier batch did that item come from?
3. What's the remaining debt to that supplier?
4. How do we track items across multiple warehouses?

This system solves all of that.

### Entity Graph

```
Franchise (Elden Ring, Star Wars)
    └── Product (Malenia Statue)
            ├── Edition (1:4 Deluxe Red) ─── Size, Version, Color
            ├── Media (images with ActiveStorage)
            └── SaleItem ─── Sale ─── Customer
                    │
                    └── PurchaseItem ─── Purchase ─── Supplier
                            │                    └── Payment (partial payments)
                            └── Warehouse
                                    └── WarehouseTransition (movement history)
```

### Key Domain Concepts

| Concept | Why It Matters |
|---------|----------------|
| **Product** | Central sellable entity. Belongs to Franchise, has many Brands, Shapes, and Editions. Auto-generates editions from size/color/version combinations. |
| **Edition** | Product variant combining Size + Version + Color. Supports "Base Model" editions for simple products. Each has SKU and pricing. |
| **Sale** | Customer order from Shopify or WooCommerce. 14 distinct statuses (pre-ordered, processing, fulfilled, cancelled, etc.). Auto-derives status from platform fulfillment/financial state. |
| **SaleItem** | Individual line item in a sale. Links to Product/Edition and gets allocated to PurchaseItem (physical inventory). Tracks quantity and fulfillment. |
| **Purchase** | Supplier order with financial tracking. Calculates debt, progress percentage, per-item costs. Supports partial payments via Payments. |
| **PurchaseItem** | Individual physical inventory unit. Stored in Warehouse, linked to SaleItem when sold. Tracks shipping cost, tracking number, dimensions. |
| **Warehouse** | Storage location for inventory. Supports default warehouse, position ordering, and movement transitions. Items relocated between warehouses. |
| **Supplier** | Vendor with purchase history and debt tracking. All purchases linked to supplier for financial reporting. |
| **Customer** | Buyer from Shopify/WooCommerce. De-duplicated by email. Stores platform-specific IDs for cross-channel tracking. |
| **Payment** | Partial payment for a Purchase. Multiple payments track supplier debt reduction. Counter cache on Purchase for efficient queries. |
| **StoreInfo** | Polymorphic join storing Shopify/WooCommerce IDs, sync timestamps (pull_time, push_time), and checksums. Enables unlimited store integrations. |
| **WarehouseTransition** | Movement history. Records when PurchaseItems move between warehouses, triggering customer notifications. |

---

## Feature Spotlight: Shopify GraphQL Integration

A production-grade GraphQL client with pagination, error handling, and media sync.

### Architecture

```
Incoming:  Shopify Webhook → Job → Parser → Importer → Model
Outgoing:  Model → Serializer → GraphQL Mutation → Shopify API
```

### Key Components

| File | Purpose |
|------|---------|
| [`Shopify::Api::Client`](app/services/shopify/api/client.rb) | GraphQL client wrapper with session management |
| [`Shopify::Graphql::*`](app/services/shopify/graphql/) | Query/mutation definitions as pure strings |
| [`Product::ShopifyParser`](app/models/product/shopify_parser.rb) | Transforms API responses to normalized hashes |
| [`Product::ShopifyImporter`](app/models/product/shopify_importer.rb) | Creates/updates records transactionally |
| [`BasePullJob`](app/jobs/shopify/base_pull_job.rb) | Template method for paginated sync |

---

## Code Patterns

### Service Objects

| Service | Responsibility | Pattern |
|---------|----------------|---------|
| [`PurchaseLinker`](app/services/purchase_linker.rb) | Match sale items to available inventory | Class method delegate |
| [`ProductMover`](app/services/product_mover.rb) | Orchestrate warehouse transfers | Class method delegate |
| [`PurchasedNotifier`](app/services/purchased_notifier.rb) | Event-driven email dispatch | Class method delegate |
| [`Shopify::Api::Client`](app/services/shopify/api/client.rb) | GraphQL operations | Instance-based |

### Concerns

| Concern | What It Provides | Used By |
|---------|------------------|---------|
| [`Shopable`](app/models/concerns/shopable.rb) | Multi-store ID lookup (`find_by_shopify_id`, `find_by_woo_id`) | Product, Edition, Sale, Customer |
| [`Searchable`](app/models/concerns/searchable.rb) | PostgreSQL full-text search via pg_search | Product, Sale, Purchase |
| [`HasAuditNotifications`](app/models/concerns/has_audit_notifications.rb) | Slack notifications on model changes | 17 audited models |
| [`HasPreviewImages`](app/models/concerns/has_preview_images.rb) | ActiveStorage images with WebP variants | Product, Warehouse, PurchaseItem |

### Background Jobs

**Inheritance Hierarchy:**
```
ApplicationJob (includes Sidekiq::Status::Worker)
├── Shopify::BasePullJob (template method pattern)
│   ├── PullProductsJob
│   └── PullSalesJob
├── Shopify::CreateProductJob
├── Shopify::PushMediaJob
├── Woo::PullSalesJob
└── ... (and more jobs)
```

**Key Patterns:**
- Cursor-based pagination for large datasets
- Exponential backoff on rate limits (429 errors)
- Idempotent operations via checksum comparison
- Job chaining for complex workflows

### Authorization (Pundit)

Role-based access control with automatic authorization:

```ruby
# app/controllers/concerns/authorization.rb
included do
  before_action :authorize_resourse
  after_action :verify_authorized
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
end
```

**Roles:** `admin` (full access), `manager` (read + limited write), `support` (read-only sales), `guest` (no access)

---

## Testing

### Test Distribution

| Type | Files | Purpose |
|------|-------|---------|
| Models | 26 | Validations, associations, scopes, business logic |
| Jobs | 20 | Background processing, API mocking, retries |
| Features | 17 | E2E browser tests with Cuprite |
| Policies | 10 | Authorization rules per role |
| Services | 8 | Service object unit tests |
| Controllers | 6 | Request integration tests |

### Testing Patterns

- **FactoryBot** with traits for variants (`:admin`, `:shopify`)
- **Cuprite** (headless Chrome) for feature specs
- **Shoulda Matchers** for one-liner validations
- **ActiveJob::TestHelper** for queue assertions
- **API Mocking** via `instance_double` and `allow().to receive()`

---

## Production Practices

### Observability

| Tool | Purpose |
|------|---------|
| Sentry | Error tracking with 100% trace sampling |
| Scout APM | Performance monitoring |
| Sidekiq::Web | Job monitoring at `/jobs` |
| PgHero | Database insights (development) |
| Prosopite | N+1 detection (development) |

### Security

| Measure | Implementation |
|---------|----------------|
| Authentication | Custom session-based with bcrypt, secure cookies (httponly + same_site lax) |
| Authorization | Pundit with automatic verification on every controller |
| CSRF | Enabled via `allow_forgery_protection` |
| Credentials | Rails encrypted credentials system |
| Timeout | rack-timeout (30s) prevents hung requests |

### Data Integrity

- **Foreign keys** on all associations
- **Audit trail** via `audited` gem (max 50 records per entity)
- **Database validations** via `database_validations` gem
- **Counter caches** for efficient queries (`payments_count`, `purchase_items_count`)

---

## Tech Stack

| Category | Technology |
|----------|------------|
| Framework | Ruby 4.x, Rails 8.x |
| Database | PostgreSQL with pg_search |
| Jobs | Sidekiq 8.x, Redis |
| APIs | Shopify GraphQL, WooCommerce REST |
| Auth | Custom sessions, Pundit |
| Frontend | Hotwire (Turbo + Stimulus), Tailwind CSS v4 |
| Testing | RSpec, Capybara, Cuprite, FactoryBot |
| Storage | Cloudflare R2 (S3-compatible) |
| Deployment | Heroku (web + worker dynos) |

---

## Running Locally

```bash
# Install dependencies
bundle install

# Setup database
bin/rails db:create db:migrate

# Run tests
bundle exec rspec

# Start server
bin/dev  # Runs web + worker + tailwind watch
```

**Requirements:** Ruby 4.0.1, PostgreSQL, Redis

---

## License

Personal project. Code is open for reference.
