# Rails Domain Architecture Principles

## Core Stance

- Prefer rich domain models and composable Active Record relations over defaulting to services, queries, or controller SQL.
- Keep logic close to the model that owns the invariant.
- Treat database-backed queries as part of the model API unless they clearly become a subsystem of their own.
- Treat `app/models` as the home for the domain, not just the home for Active Record tables.

## Use the Base Model as a Composition Root

- Keep the main model file short.
- Put the model's broad associations, validations, top-level ordering or preload scopes, and included capability modules there.
- Use the file as the place where another developer can understand what the model is made of.

```ruby
class Order < ApplicationRecord
  include Fulfillable, Payable, Searchable

  belongs_to :account
  belongs_to :customer

  scope :latest, -> { order(created_at: :desc, id: :desc) }
  scope :preloaded, -> { includes(:customer, :line_items, :payment) }
end
```

## Extract Cohesive Capability Modules

- Create `app/models/<model>/<capability>.rb` when a business concept owns both read and write behavior.
- Let that module own the related associations, scopes, callbacks, predicates, commands, and private helpers.
- Name capability modules after business language such as `Assignable`, `Closable`, `Publishable`, `Fulfillable`, or `Searchable`.
- Avoid grab-bag modules with vague names such as `Manageable`, `Helpers`, or `Utils`.
- Prefer capability modules over giant services when the behavior still belongs to one aggregate.

```ruby
module Order::Fulfillable
  extend ActiveSupport::Concern

  included do
    has_one :shipment, dependent: :destroy

    scope :fulfilled, -> { joins(:shipment) }
    scope :unfulfilled, -> { where.missing(:shipment) }
  end

  def fulfill!(carrier:)
    transaction do
      create_shipment!(carrier: carrier)
      touch(:fulfilled_at)
    end
  end
end
```

## Reserve app/models/concerns for True Cross-Cutting Behavior

- Put behavior in `app/models/concerns` only when it is shared across multiple models.
- Use those concerns for generic templates such as `Searchable`, `Eventable`, `Filterable`, or `Notifiable`.
- Keep model-specific adaptation in the model namespace.

Good pattern:
- `app/models/concerns/searchable.rb` defines the shared indexing contract.
- `app/models/order/searchable.rb` defines how `Order` satisfies that contract.

Avoid:
- Putting single-model business rules into `app/models/concerns` just because the base model is getting large.

## Treat Some Concerns as Internal Frameworks

- A concern may be more than shared helper code.
- It can define:
- callbacks
- required methods
- template methods
- overridable hooks
- expected associations or scopes

- This pattern works well for concerns such as:
- search indexing
- event tracking
- mentions
- storage tracking
- notification fan-out

- If you use this style, make the contract obvious in code comments or method names.
- Keep the number of required methods small and coherent.

## Use app/models for Domain-Adjacent POROs Too

- Put plain Ruby domain objects in `app/models` when they are part of the domain language and sit next to the data they operate on.
- Good examples include:
- Form objects
- Query subsystem objects
- Payload builders
- Text or notification description objects
- Search helpers
- Import/export workflow objects
- Time window parsers or state mappers

Avoid:
- Creating `app/services` by default when a PORO really belongs under a model namespace.
- Hiding important domain objects in `lib/` just because they are not Active Record classes.

## Allow Collection-Level APIs on Associations

- If a collection has a meaningful domain API, put it on the association proxy with `has_many ... do`.
- Good collection-level commands include:
- `grant_to`
- `revoke_from`
- `revise`
- batch helpers tightly coupled to the parent and child relation

- This can be cleaner than inventing a separate service object whose only job is to manipulate one association collection.

## Organize Scopes by Business Meaning

- Put scopes beside the associations and state they depend on.
- Name scopes after business states or user-visible slices.
- Keep scopes small and composable.
- Make scopes return `ActiveRecord::Relation` values and avoid eager materialization inside them.
- Use a few dispatcher scopes only when translating a UI choice into smaller scopes.

Good scope categories:
- State scopes: `open`, `closed`, `active`, `archived`, `awaiting_review`
- Association-driven scopes: `assigned_to`, `tagged_with`, `owned_by`
- Ordering scopes: `latest`, `chronologically`, `alphabetically`
- Read-shape scopes: `preloaded`, `with_customer`, `with_line_items`
- UI dispatch scopes: `indexed_by`, `sorted_by`

Avoid:
- One giant scope that accepts many unrelated arguments.
- Scope names that leak SQL mechanics instead of business intent.

## Start Queries from the Real Boundary

- Begin from the relation that already encodes tenancy, authorization, or ownership.
- Prefer entry points such as `Current.user.accessible_orders`, `Current.account.orders`, or `customer.orders`.
- Avoid starting from `Order.all` in controllers and rebuilding access rules ad hoc.

This boundary often belongs on a related model:

```ruby
class User < ApplicationRecord
  has_many :accessible_orders, through: :memberships, source: :orders
end
```

Also apply this rule outside controllers:
- Jobs
- Channels
- Mailers
- Background workflow objects

## Use Named Preload Scopes for Common Read Shapes

- Capture repeated `includes`, `preload`, or `eager_load` sets in a named scope.
- Treat these scopes as read models for controllers and views.
- Keep them specific enough to be meaningful and common enough to be reused.

Examples:
- `preloaded`
- `with_users`
- `for_index`
- `for_api`

Treat preload scopes as part of the public read API of the model.

## Introduce Query Objects Only for First-Class Query Subsystems

- Keep straightforward filtering in model scopes.
- Introduce a dedicated query object when the query has its own lifecycle, persistence, parameter normalization, backend, or UI identity.
- Typical examples:
- Saved filters
- Full-text search
- Reporting
- Adapter-specific search backends
- Large cross-model cleanup queries

- Avoid tiny query wrappers that only add one preload shape, ordering, or simple relation composition.
- If a query object would only wrap `includes`, `order`, or one reusable `where`, prefer a named scope instead.

Model-adjacent query objects still belong under `app/models`, not in a dumping-ground service layer.

## Introduce Service Objects Only for Orchestration

- Use a service object when the work coordinates multiple aggregates, external APIs, background workflows, or side effects that do not clearly belong to one model capability.
- Keep services small and explicit.
- Do not move domain logic into a service just because a model file became crowded.
- Before keeping a service in `app/services`, ask whether it is really a model-area workflow object that should live under `app/models/<namespace>/`.

Good service cases:
- Charge a payment provider and persist resulting records
- Synchronize data from an external API
- Run a multi-step import/export pipeline

Bad service cases:
- Filter one model with a handful of where clauses
- Move a state transition out of the owning model
- Hide a scope because the controller looked too long

## Use Domain Events as a Spine When Side Effects Multiply

- If one business action needs to feed several downstream behaviors, consider a first-class event model.
- One event can drive:
- activity timelines
- notifications
- webhooks
- system comments
- push payloads

- This is often cleaner than sprinkling independent callbacks across many models with duplicated branching logic.

## Let Lifecycle States Gate Downstream Behavior

- Some domain states intentionally suppress side effects.
- Draft, inactive, cancelled, inaccessible, or pending states may block:
- mentions
- search indexing
- notifications
- pushes
- email delivery

- Keep those gates near the owning capability instead of scattering `return if draft?` style checks across unrelated layers.
- Treat these gates as part of the public domain contract and test them explicitly.

## Treat Access Loss as a Domain Transition

- Authorization is a request concern, but losing access can also be a domain event with cleanup consequences.
- A domain boundary such as board membership or access may own cleanup of:
- watches
- pins
- notifications
- mentions
- visibility-derived records

- Keep that cleanup near the access concept, sometimes with a focused async job when the fan-out is large.

## Put Temporal Rules in Domain Objects

- If a time-based rule is meaningful to users, prefer storing and testing it in the model layer.
- Good examples include:
- inactivity thresholds
- bundling windows
- expiration
- last activity tracking
- cache or freshness rules that depend on business context

- The recurring scheduler should trigger the work, but the rule itself should remain discoverable on the domain object.

## Allow Domain-Owned External Representations

- Keep screen-specific HTML in views and helpers.
- But allow model-adjacent objects or capability modules to own representations that are part of the product's external interface:
- export payloads
- webhook payloads
- notification payloads
- prompt representations for AI features
- text descriptions used across channels

- The key distinction is:
- UI rendering for a screen belongs at the edge.
- Domain representations reused across exports, jobs, APIs, integrations, or AI features can live near the domain.

## Keep Request Context Explicit

- Use `Current` for request-scoped context such as account, user, identity, session, timezone, platform, and tracing metadata.
- Set `Current` at the request boundary, usually in middleware, base controllers, or connection setup.
- Rehydrate the needed context in jobs, mailers, and channels instead of reaching into global state implicitly.
- Keep access and tenant boundaries explicit in the relation you start from.

## Keep Controllers Thin

- Let controllers choose the starting relation.
- Let controllers compose named scopes and preload scopes.
- Let models own commands, invariants, and transactions.
- Use controller concerns for loading filter or search context, not for relocating business rules.
- Prefer focused nested resources and state-transition endpoints over giant multi-purpose controllers.

## Keep Writes Close to Reads

- When a capability has state scopes, also give it matching predicates and commands when appropriate.
- Keep the write-side API near the read-side API so the business concept stays understandable.
- Wrap multi-record state changes in transactions.

## Use Callbacks Deliberately, Not Fearfully

- Callbacks are acceptable when they stay local to a capability and maintain that concept's adjacent data or fan-out.
- Good callback uses include:
- creating an event after a state change
- enqueueing delivery jobs
- updating a search index
- maintaining a ledger or materialized total
- refreshing broadcasts

- Avoid callbacks that hide large cross-aggregate workflows with surprising ordering dependencies.

## Avoid Default Scope

- Do not use `default_scope` for tenancy, soft deletion, ordering, or visibility.
- Make those rules explicit in named scopes or in the starting relation.
- Favor visible composition over hidden model-wide behavior.
