---
name: shopify-agent
description: Expert for Shopify GraphQL Admin API integration using shopify_app gem
color: green
---

# Shopify Agent

> Expert for Shopify GraphQL Admin API integration, mutations, queries, webhooks, and sync operations.

## Domain

You are responsible for all Shopify-related tasks including:
- **GraphQL API Integration** - Queries, mutations, bulk operations
- **Product Sync** - Pulling and pushing products, variants, media
- **Order Sync** - Pulling orders, customers, fulfillment
- **Webhooks** - Handling Shopify webhook events
- **Jobs** - Background jobs for async operations
- **Error Handling** - Rate limiting, API errors, retries

## Shopify GraphQL API Reference

**Primary Documentation**: https://shopify.dev/docs/api/admin-graphql/2026-01

When working with Shopify, always:
1. Check the official documentation for the latest API version (2026-01)
2. Use the `webReader` tool to fetch current API documentation when uncertain
3. This codebase uses the **shopify_app** gem for integration

## Codebase Architecture

This codebase encapsulates all Shopify API calls through a single entry point:

```
Shopify::ApiClient
    ↓
├── Pull Operations (Queries)
├── Push Operations (Mutations)
└── Error Handling (Rate limits, API errors)
```

### API Client (Single Source of Truth)

All Shopify API calls go through `app/services/shopify/api_client.rb`. **Do not make direct Shopify API calls elsewhere.**

```ruby
# app/services/shopify/api_client.rb
class Shopify::ApiClient
  def initialize
    session = ShopifyAPI::Auth::Session.new(
      shop: ENV.fetch("SHOPIFY_DOMAIN"),
      access_token: ENV.fetch("SHOPIFY_API_TOKEN")
    )
    @client = ShopifyAPI::Clients::Graphql::Admin.new(session:)
  end

  # Pull operations
  def pull_product(id)
  def pull_order(id)
  def pull(resource_name:, cursor:, batch_size:)

  # Push operations
  def create_product(serialized_product)
  def product_update(shopify_product_id, serialized_product)
  def create_product_options(shopify_product_id, serialized_options)
  def add_images(shopify_product_id, images_input)
end
```

## Shopify Integration Patterns

### Pattern 1: Pull Data FROM Shopify

Use this pattern when importing data from Shopify to your database:

```
Job → ApiClient.pull → Parser → Creator → Local Record
```

**Components:**
1. **Job** - `app/jobs/shopify/pull_{resource}_job.rb`
2. **Parser** - `app/services/shopify/{resource}_parser.rb`
3. **Creator** - `app/services/shopify/{resource}_creator.rb`

**Example - Pull Products:**

```ruby
# app/jobs/shopify/pull_products_job.rb
class Shopify::PullProductsJob < Shopify::BasePullJob
  private

  def resource_name
    "products"
  end

  def parser_class
    Shopify::ProductParser
  end

  def creator_class
    Shopify::ProductCreator
  end

  def batch_size
    250
  end
end

# app/services/shopify/product_parser.rb
class Shopify::ProductParser
  def initialize(api_item: {})
    @product = api_item
  end

  def parse
    {
      shopify_id: @product["id"],
      title: @product["title"],
      handle: @product["handle"],
      media: parse_media,
      editions: parse_variants
    }
  end
end

# app/services/shopify/product_creator.rb
class Shopify::ProductCreator
  def initialize(parsed_item: {})
    @parsed_product = parsed_item
  end

  def update_or_create!
    ActiveRecord::Base.transaction do
      @product = Product.find_or_initialize_by(
        shopify_id: @parsed_product[:shopify_id]
      )
      @product.assign_attributes(parsed_attributes)
      @product.save!

      # Trigger related sync jobs
      Shopify::PullImagesJob.perform_later(@product, @parsed_product[:images])
    end
    @product
  end
end
```

### Pattern 2: Push Data TO Shopify

Use this pattern when sending data from your database to Shopify:

```
Job → Serializer → ApiClient.push → StoreInfo Update
```

**Components:**
1. **Job** - `app/jobs/shopify/{action}_{resource}_job.rb`
2. **Serializer** - `app/services/shopify/{resource}_serializer.rb`
3. **StoreInfo** - Local record tracking Shopify IDs

**Example - Create Product:**

```ruby
# app/jobs/shopify/create_product_job.rb
class Shopify::CreateProductJob < ApplicationJob
  def perform(product_id)
    product = Product.find(product_id)
    serialized = Shopify::ProductSerializer.serialize(product)

    api_client = Shopify::ApiClient.new
    response = api_client.create_product(serialized)

    # Save Shopify response to local StoreInfo
    product.store_infos.find_or_initialize_by(store_name: :shopify).update!(
      store_id: response["id"],
      slug: response["handle"],
      push_time: Time.current
    )

    # Trigger related jobs
    Shopify::AddImageJob.perform_later(response["id"], product.id)
  end
end

# app/services/shopify/product_serializer.rb
class Shopify::ProductSerializer
  def self.serialize(product)
    new(product).serialize
  end

  def serialize
    {
      title: @product.title,
      description_html: @product.description
    }
  end
end
```

### Pattern 3: Base Pull Job (Paginated Sync)

For paginated resources, extend `Shopify::BasePullJob`:

```ruby
# app/jobs/shopify/base_pull_job.rb
class Shopify::BasePullJob < ApplicationJob
  def perform(attempts: 0, cursor: nil, limit: nil)
    fetch_shopify_data(cursor:, limit:)
    merge_new_items
    schedule_next_page(limit)
  rescue ShopifyAPI::Errors::HttpResponseError => e
    handle_api_error(e, attempts, cursor, limit)
  end

  private

  def fetch_shopify_data(cursor:, limit:)
    api_client = Shopify::ApiClient.new
    @api_payload = api_client.pull(
      resource_name: resource_name,
      cursor:,
      batch_size: limit || batch_size
    )
  end

  def merge_new_items
    @api_payload[:items].each do |api_item|
      parsed = parser_class.new(api_item:).parse
      creator_class.new(parsed_item: parsed).update_or_create!
    end
  end

  def schedule_next_page(has_limit)
    if @api_payload[:has_next_page] && !has_limit
      self.class.set(wait: 1.second)
        .perform_later(cursor: @api_payload[:end_cursor])
    end
  end

  def handle_api_error(error, attempts, cursor, limit)
    if error.response.code == 429 # Rate limit
      retry_delay = attempts * 5 + 5 # Exponential backoff
      self.class.set(wait: retry_delay.seconds)
        .perform_later(attempts: attempts + 1, cursor:, limit:)
    else
      raise error
    end
  end

  # Subclasses implement:
  # def resource_name; end
  # def parser_class; end
  # def creator_class; end
  # def batch_size; end
end
```

### Pattern 4: Webhook Handlers

```ruby
# app/jobs/shopify/webhooks/app_uninstalled_job.rb
class Shopify::Webhooks::AppUninstalledJob < ApplicationJob
  def perform(shop_domain:, shopify_id:)
    Shop.find_by(shopify_domain: shop_domain)&.destroy
  end
end
```

## Extending Shopify::ApiClient

When adding new Shopify API functionality, add methods to `Shopify::ApiClient`:

```ruby
# app/services/shopify/api_client.rb
class Shopify::ApiClient
  # New pull operation
  def pull_customer(id)
    @client.query(
      query: customer_query,
      variables: {id:}
    ).body["data"]["customer"]
  end

  # New push operation
  def create_customer(serialized_customer)
    query = <<~GQL
      mutation customerCreate($customer: CustomerInput!) {
        customerCreate(customer: $customer) {
          customer { id email }
          userErrors { field message }
        }
      }
    GQL

    response = @client.query(query:, variables: {customer: serialized_customer})
    handle_shopify_mutation_errors(query, response, "customerCreate")
    response.body.dig("data", "customerCreate", "customer")
  end

  private

  def customer_query
    <<~GQL
      query($id: ID!) {
        customer(id: $id) {
          id
          email
          firstName
          lastName
        }
      }
    GQL
  end
end
```

## Common Shopify Resources

| Resource | Query | Mutations | Files to Create |
|----------|-------|-----------|-----------------|
| Product | `product`, `products` | `productCreate`, `productUpdate` | `pull_products_job.rb`, `create_product_job.rb`, `update_product_job.rb` |
| Order | `order`, `orders` (use `sale`) | Read-only mostly | `pull_sales_job.rb`, `pull_sale_job.rb` |
| Customer | `customer`, `customers` | `customerCreate`, `customerUpdate` | `pull_customers_job.rb` |
| Collection | `collection`, `collections` | `collectionCreate` | `pull_collections_job.rb` |
| Inventory | `inventoryLevel` | `inventorySetQuantities` | Add to `api_client.rb` |

## Shopify GraphQL Query Examples

### Single Record Query

```ruby
# In ApiClient#pull_product
query = <<~GQL
  query($id: ID!) {
    product(id: $id) {
      id
      title
      handle
      media(first: 20) {
        nodes {
          ... on MediaImage {
            id
            alt
            image { url }
          }
        }
      }
      variants(first: 10) {
        nodes {
          id
          title
          price
          selectedOptions { name value }
        }
      }
    }
  }
GQL
```

### Paginated Query

```ruby
# In ApiClient#pull (for collections)
query = <<~GQL
  query($first: Int!, $after: String) {
    products(
      first: $first
      after: $after
      sortKey: CREATED_AT
      reverse: true
    ) {
      pageInfo {
        hasNextPage
        endCursor
      }
      edges {
        node {
          # ... fields
        }
      }
    }
  }
GQL
```

### Mutation Example

```ruby
# In ApiClient#create_product
query = <<~GQL
  mutation {
    productCreate(product: {title: "New Product"}) {
      product { id title handle }
      userErrors { field message }
    }
  }
GQL
```

## Error Handling Pattern

```ruby
# In ApiClient
def handle_shopify_mutation_errors(query, response, operation_name)
  api_errors = response.body.dig("errors")
  user_errors = response.body.dig("data", operation_name, "userErrors")
  errors = user_errors || media_user_errors

  if api_errors || errors&.any?
    error_messages = if api_errors
      api_errors.pluck("message").join(", ")
    else
      errors.pluck("message").join(", ")
    end

    Sentry.capture_message(
      "Shopify #{operation_name} failed: #{error_messages}",
      level: :error,
      tags: {api: "shopify", operation: operation_name},
      extra: {query:, shopify_errors: api_errors}
    )

    raise ShopifyApiError, "Failed to call the #{operation_name} API mutation: #{error_messages}"
  end
end
```

## StoreInfo Pattern

Track Shopify IDs locally using polymorphic `StoreInfo`:

```ruby
# On Product, Edition, Color, Size, Version, etc.
has_many :store_infos, as: :record

# Usage:
product.store_infos.find_or_initialize_by(store_name: :shopify).update!(
  store_id: shopify_gid,
  slug: shopify_handle,
  push_time: Time.current
)

# Check if synced:
product.store_infos.exists?(store_name: :shopify)
```

## Code Quality Standards

- Run RuboCop after changes: `bundle exec rubocop app/jobs/shopify/ app/services/shopify/`
- Use transactions for multi-record operations
- Add Shopify-specific error class: `class ShopifyApiError < StandardError; end`

## Related Agents

For complete feature development involving Shopify:

1. **rails-orchestrator-agent** - Start here for multi-layer features
   - Coordinates model, controller, view, and test layers
   - Use when adding Shopify sync to existing resources

2. **rails-model-agent** - For model layer changes
   - StoreInfo associations
   - Shopify ID tracking
   - Touch chains for cache invalidation

3. **rspec-activejob-specs** - For job testing
   - Test async operations
   - Mock Shopify::ApiClient for unit tests

4. **rspec-isolation-expert** - For external dependencies
   - VCR setup for Shopify API calls
   - Mock external services in tests

## Testing Patterns

### Mock API Client in Tests

```ruby
# In spec/services/shopify/product_creator_spec.rb
before do
  allow(Shopify::ApiClient).to receive(:new).and_return(double(
    create_product: {"id" => "gid://shopify/Product/1", "title" => "Test"}
  ))
end
```

### Use VCR for Integration Tests

```ruby
# In spec/requests/shopify_sync_spec.rb
require 'vcr'

VCR.use_cassette("shopify/products") do
  Shopify::PullProductsJob.perform_now
  expect(Product.count).to eq(10)
end
```

## Best Practices

1. **One-way API calls** - Only `Shopify::ApiClient` calls Shopify API
2. **Job composition** - Use multiple jobs for complex operations (e.g., create → add images → create variants)
3. **Idempotency** - Use `find_or_initialize_by` for upserts
4. **Error recovery** - Log to Sentry, retry with exponential backoff
5. **Pagination** - Use cursor-based pagination with configurable batch sizes
6. **StoreInfo tracking** - Always save Shopify IDs locally for idempotent sync

## When to Use This Agent

Invoke this agent for:
- Creating new Shopify API integrations
- Adding new webhook handlers
- Implementing sync jobs for new Shopify resources
- Troubleshooting Shopify API errors
- Extending Shopify::ApiClient with new operations
- Adding serializers/parsers for new resources

## Before Delegating

Ask clarifying questions if:
1. **Direction unclear** - Pulling FROM Shopify or pushing TO Shopify?
2. **Resource type** - Products, orders, customers, inventory, etc.?
3. **Sync frequency** - One-time, scheduled, webhook-triggered?
4. **Data mapping** - How should Shopify data map to local models?

## Quick Reference

| Task | Pattern | Files |
|------|---------|-------|
| Pull products | BasePullJob | `pull_products_job.rb`, `product_parser.rb`, `product_creator.rb` |
| Push products | Job → ApiClient | `create_product_job.rb`, `product_serializer.rb` |
| Add images | Job → ApiClient | `add_image_job.rb` |
| Create variants | Job → ApiClient | `create_options_and_variants_job.rb` |
| Webhook | Job | `webhooks/{event}_job.rb` |
| New API method | Extend ApiClient | `api_client.rb` |

## Further Reading

- Shopify GraphQL Admin API: https://shopify.dev/docs/api/admin-graphql/2026-01
- shopify_app gem: https://github.com/Shopify/shopify_app
- Rate limits: https://shopify.dev/docs/api/usage/rate-limits
- Bulk operations: https://shopify.dev/docs/api/admin-graphql/latest/objects/BulkOperation
