# Controllers and Request Refactors

Use this guide when refactoring legacy Rails controllers that currently mix request mechanics, SQL, transactions, policy checks, workflow logic, and rendering concerns.

## Core Read

- Controllers should be request adapters, not the main home of domain logic.
- Do not treat the current controller shape as the target architecture.
- Treat controller code as evidence for where the real ownership should move.

## Default Rule For Legacy Controllers

- Keep only these responsibilities in the controller:
- load the request boundary
- permit or normalize params
- choose the response format
- render, redirect, or set flash

- If logic does more than that, first ask where it belongs:
- `app/controllers/concerns/` for repeated request mechanics
- `app/models/<model>/<capability>.rb` for aggregate-owned behavior
- `app/models/<model>/<workflow>.rb` for aggregate-local orchestration
- `app/views/` or helpers for presentation

## 1. What Usually Moves Out Of Controllers

- long relation chains
- access or tenant scoping repeated across actions
- transaction blocks that update one aggregate and its children
- branching on business state
- notification recipient or payload logic
- hand-built HTML or JSON fragments
- repeated preload shapes

## 2. What Stays In Controllers

- boundary loading such as `Current.user.products` or `Current.account.sales`
- action-specific params and redirects
- response negotiation for `html`, `json`, or `turbo_stream`
- shallow orchestration of one request

## 3. Default File Targets

Request mechanics:
- `app/controllers/concerns/<resource>_scoped.rb`
- `app/controllers/concerns/authentication.rb`
- `app/controllers/concerns/authorization.rb`
- `app/controllers/concerns/current_timezone.rb`
- `app/controllers/public/base_controller.rb`
- `app/controllers/account/base_controller.rb`

Aggregate-local orchestration:
- `app/models/product/upsert.rb`
- `app/models/product/catalog_change.rb`
- `app/models/sale/creation.rb`
- `app/models/sale/status_change.rb`
- `app/models/purchase/warehousing.rb`

Reusable read shapes:
- named scopes on the owning model such as:
- `Product.for_listing`
- `Product.for_details`
- `Sale.ordered_by_shop_created_at`

Rendering:
- `app/helpers/<resource>_helper.rb`
- `app/views/<resource>/*.html.erb`
- `app/views/<resource>/*.json.jbuilder`
- `app/views/<resource>/*.turbo_stream.erb`

## 4. Refactor Patterns

### Long Index Action

- Move access rules to the starting relation.
- Move preload sets to named scopes.
- Move filtering to scopes or a first-class query subsystem when justified.

### Heavy Create or Update Action

- If one aggregate and its child records are being coordinated, create a model-area workflow object.
- Keep the controller responsible for params and response only.

### Repeated Loader Logic

- Extract a controller concern when several controllers load the same boundary records or enforce the same request policy.
- Keep business invariants out of the concern.

## 5. What Not To Preserve

- Do not preserve a large transaction block in the controller just because it currently works.
- Do not preserve policy-like branching in multiple actions if one scoped entry relation can own the boundary.
- Do not preserve controller-built JSON hashes if an explicit template would be clearer.
- Do not preserve notification or enqueue logic in the controller if the domain object can expose the right command.

## 6. Anti-Default LLM Checklist

- Do not answer “extract a service” without naming the target file.
- Do not move business logic into controller concerns.
- Do not treat repeated `includes` or `order` chains as controller details if they are reused read shapes.
- Do not leave refactor destination vague when the right answer is a file under `app/models/<model>/`.
