# Rails Domain Architecture Principles

Use this file for non-obvious model-layer rules in this repo.

## Core Principle

Keep behavior close to the domain that owns it.

A reader should understand where a business concept lives before understanding how it is implemented.

## Core Rules

- Treat `app/models` as the home for domain code, not just Active Record tables.
- Keep base model files short. They should read like a table of contents.
- Prefer model capabilities over detached service objects.
- Extract objects only when they represent a real domain concept.
- Use domain language for classes, methods, scopes, and workflows.
- Prefer rich model APIs with business verbs over controller-shaped workflows.
- Prefer named scopes and preload scopes over controller-built SQL or tiny query wrappers.
- Reserve `app/models/concerns` for true cross-model behavior.
- Keep reusable cross-process representations near the domain that owns them.
- Do not extract code only to reduce file size.

## Base Model Boundary

The base model file should mostly contain:

- includes;
- core associations;
- validations;
- broad ordering scopes;
- broad preload scopes;
- light model wiring.

The base file should not become the home for concept-heavy behavior.

Prefer:

```ruby
class Product < ApplicationRecord
  include Pricing
  include Inventory
  include Publishing
end
```

Over one large model file containing every pricing, inventory, and publishing rule inline.

## Capability Modules

Use `app/models/<model>/<capability>.rb` for one business concept owned by one aggregate.

A capability module may own:

- associations;
- scopes;
- callbacks;
- predicates;
- commands;
- private helpers.

Prefer:

```ruby
product.publish!
product.archive!
product.restock!
```

Over:

```ruby
ProductPublisher.call(product)
ProductArchiveService.call(product)
ProductRestockManager.new(product).call
```

when the behavior belongs to the product domain itself.

Name modules after business concepts, not technical buckets.

Prefer:

```ruby
Product::Pricing
Product::Inventory
Product::Publishing
```

Over:

```ruby
Product::Helpers
Product::Utils
Product::Actions
```

## Concerns

Use `app/models/concerns` only when the same behavior truly applies to multiple models.

Concerns may define contracts, hooks, and callbacks when they act as small internal frameworks.

Do not move single-model business rules into concerns just to keep the base model shorter.

## Model-Area Objects

Keep POROs in `app/models` when they are part of the domain language.

Good reasons to create a model-area object:

- a workflow has its own domain name;
- a query becomes a first-class subsystem;
- an import/export process has real identity;
- an external integration belongs to a domain concept;
- a value object represents a domain idea;
- one model would otherwise know too much about infrastructure.

Do not create a new object if its best name is only:

```ruby
ProductService
ProductManager
ProductProcessor
ProductHandler
```

If the object cannot be named using domain language, it probably should not exist.

## Scopes and Queries

Prefer named scopes when the query is composable and belongs to one model.

Prefer:

```ruby
Current.user.accessible_products.active.recent
```

Over:

```ruby
ProductQuery.new(user: Current.user, status: :active).recent
```

unless querying itself has become a first-class subsystem.

Create a query object only when the query represents something larger, such as:

- saved filters;
- reporting;
- full-text search;
- adapter-specific search;
- multi-step import/export lookup.

## Representation Boundary

Screen-only wording belongs outside the model layer.

Reusable representations that cross jobs, sync flows, exports, notifications, webhooks, or prompts may stay near the model that owns them.

Prefer domain-owned representations when they are product interfaces, not just view formatting.

## What Codex Often Gets Wrong

Avoid:

- extracting a single-model capability away from the model layer only because the model has many methods;
- defaulting to service objects when one clear model method would express the action;
- moving composable scopes into query objects too early;
- hiding single-model domain logic in `app/models/concerns`;
- flattening association-local behavior into detached manager objects;
- renaming business actions after forms, params, controllers, or transport steps;
- assuming callbacks are bad when they maintain one local concept;
- creating generic objects named `Manager`, `Processor`, `Handler`, or `Service`.

## Placement Shortcuts

- one aggregate owns the behavior -> `app/models/<model>/<capability>.rb`
- one aggregate owns a larger workflow -> `app/models/<model>/<workflow>.rb`
- shared cross-model behavior -> `app/models/concerns/<concern>.rb`
- repeated read shape -> named scope on the owning model
- first-class query subsystem -> `app/models/<subsystem>/`
- import/export subsystem -> `app/models/<domain>/<import_or_export>.rb`
- reusable domain representation -> near the model that owns the concept

## Refactor Stance

- Treat current placement as evidence, not as architecture worth preserving.
- Name explicit target files instead of saying "extract an object".
- Move one coherent slice at a time.
- Improve names as well as placement.
- Public APIs should sound like the business domain.
- Put the main method first, then place private helpers below it in reading order.

## Rule of Thumb

If a behavior naturally reads as:

```ruby
product.publish!
user.grant_access!
account.active_subscription
```

it probably belongs close to the model that owns the concept.

If a new object cannot be named as a domain concept, do not extract it.
