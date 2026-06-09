# Rails Architecture

Design the backend around domain ownership.

A reader should understand where a business concept lives before understanding how it is implemented.

## Core Rules

- Keep behavior close to the domain that owns it.
- Prefer model capabilities over detached service objects.
- Extract objects when they represent a real domain concept, not just to reduce model size.
- Use domain language for classes, methods, scopes, and workflows.
- Keep controllers thin; controllers load data, compose scopes, and invoke domain operations.
- Keep jobs thin; jobs transport work, domain objects perform work.
- Start reads from permission-scoped or tenant-scoped relations.
- Use `Current` for request-scoped context.
- Keep presentation concerns at the edge.
- Keep external representations (exports, payloads, prompts, webhooks) near the domain that owns them.

## Prefer

Prefer:

```ruby
Current.user.accessible_orders
```

Over:

```ruby
Order.where(account_id: current_account.id)
```

---

Prefer:

```ruby
order.publish!
order.cancel!
order.refund!
```

Over:

```ruby
OrderPublisher.call(order)
OrderCancellationService.call(order)
OrderRefundService.call(order)
```

when the behavior belongs to the order domain itself.

---

Prefer:

```ruby
class Order
  include Billing
  include Fulfillment
  include Notifications
end
```

Over:

```ruby
OrderService
OrderManager
OrderProcessor
```

when those concepts are simply capabilities of the same domain object.

---

Prefer:

```ruby
Current.user.accessible_orders.active.recent
```

Over:

```ruby
OrderQuery.new(...)
```

unless querying itself becomes a first-class subsystem.

---

Prefer:

```ruby
PublishOrderJob.perform_later(order)

class PublishOrderJob
  def perform(order)
    order.publish!
  end
end
```

Over:

```ruby
class PublishOrderJob
  def perform(order)
    ...
    ...
    ...
  end
end
```

Jobs should transport work, not own workflows.

## Extract Only When The Concept Exists

Create a new object when it represents:

- A workflow
- A query subsystem
- An import/export subsystem
- An external integration
- A domain-specific value object
- A reusable cross-domain capability

Do not extract objects purely because a model has many methods.

## Avoid

- Service objects that mirror model names.
- Query objects for ordinary ActiveRecord scopes.
- Business logic in controllers.
- Domain workflows in jobs.
- Request-scoping duplicated across controllers.
- Generic names such as `Manager`, `Processor`, `Handler`, or `Service`.
- Moving domain behavior away from the domain that owns it.

## Rule of Thumb

If a behavior naturally reads as:

```ruby
order.publish!
user.grant_access!
account.active_subscription
```

it probably belongs close to the model that owns the concept.

If a new object cannot be named using domain language, it probably should not exist.

## Resource Design

Prefer resource boundaries over action-heavy controllers.

Prefer:

```
POST /orders/:id/publication
```

Over:

```
POST /orders/:id/publish
```

when the action represents a first-class concept.

Use real write verbs for command endpoints.
