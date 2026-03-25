# Rails Full-Stack Architecture

Use this file for the non-obvious request, controller, and presentation rules in this repo.

## Request Boundary

- Start from the real access boundary, not `Model.all`.
- Keep `Current` small. In this repo it stores `session` and delegates `user`.
- Rehydrate any request-dependent context explicitly in jobs or other async code when needed.

## Controllers

- Controllers are request adapters, not domain homes.
- Keep in controllers:
  - boundary loading
  - params normalization
  - format choice
  - render or redirect
- Move out of controllers:
  - long relation chains
  - aggregate-local transactions
  - business-state branching
  - recipient or payload logic
  - hand-built HTML or JSON
- Prefer direct calls to intention-revealing model APIs before introducing a service layer between controllers and models.
- Small params normalization can stay in the controller. If one form needs several normalization helpers, nested-form translation, or failed-submit rebuilding, extract narrow form objects such as `Product::FormPayload` or `Product::FormRehydrator` under `app/models/<model>/`.
- If the controller action reads like a business verb, that verb probably belongs on the owning model or model-area object.
- When a side-effect action is really its own concept, prefer a dedicated resource controller such as `Sales::PurchaseItemLinksController` or `Warehouses::PositionsController` over growing one large top-level controller.
- Use real write verbs for command endpoints. A pull, move, link, or webhook-confirm action should not hide behind `GET` just because the UI triggers it from a button or menu.
- Prefer small controller concerns for repeated resource seams such as `ProductScoped`, `SaleScoped`, or `WarehouseScoped`.
- Controller concerns should hold shared request-layer behavior, not one controller's private organization. “Shared” can mean app-wide or reused across one namespaced controller family, as in Fizzy’s `CardScoped` and `BoardScoped`.
- Inline Turbo interactions such as edit or cancel or update flows can still be resourceful; a small singular nested controller is often cleaner than `edit_foo`, `cancel_foo`, and `update_foo` actions on the parent controller.
- Collection workflows can be resourceful too. `Purchases::MovesController`, `Purchases::ProductEditionsController`, and `Dashboard::LastOrdersPullsController` are valid shapes when the concept lives at the collection or dashboard boundary.
- After route extraction, update helper code and shared UI primitives to use the new route contract. Generic helpers should prefer route helpers or correctly shaped polymorphic calls plus the right `turbo_method`, rather than assuming the old path shape still works.

## Placement Decisions

- repeated request mechanics -> base controllers or controller concerns
- repeated request mechanics across one controller family -> controller concern
- aggregate-owned behavior -> `app/models/<model>/<capability>.rb`
- aggregate-local orchestration -> `app/models/<model>/<workflow>.rb`
- complex form input translation -> `app/models/<model>/form_payload.rb`
- failed-submit form rebuilding -> `app/models/<model>/form_rehydrator.rb`
- presentation-only branching -> helpers, partials, Jbuilder, Turbo templates
- repeated resource loading across several small controllers -> `app/controllers/concerns/<resource>_scoped.rb`
- one controller needs internal cleanup but no other controller shares the logic -> keep private methods or extract another controller, not a single-use concern
- side-effect endpoint that maps cleanly to one concept -> nested singular resource controller
- collection-level side effect or Turbo endpoint -> singular collection resource controller under the owning namespace
- inline field editor with its own edit/show/update cycle -> nested singular resource controller under the owning resource

## Presentation Boundary

- Keep screen-specific logic at the edge.
- Do not add presenters by default.
- Use this sorting rule:
  - one screen or one response format -> helper, partial, Jbuilder, Turbo template
  - reused across jobs, exports, notifications, or integrations -> model-area representation object
  - business identity or state text -> model or capability module

## What Codex Often Gets Wrong

- Do not keep screen-specific text on the model just because it is reused across templates.
- Do not move true domain payload builders into helpers.
- Do not leave controllers orchestrating multi-step aggregate updates when the sequence belongs to one model.
- Do not introduce a form object or service object by reflex when a named model command would be simpler and clearer.
- Do not pass `ActionController::Parameters` into model APIs. Translate request-shape data at the edge or in a narrow form payload object first.
- Do not let a controller accumulate half a dozen `normalized_*` helpers when the form shape itself has become a concept.
- Do not keep bolting member actions onto one broad controller when the route can become a first-class nested resource.
- Do not leave command endpoints on `GET` after promoting them into their own concept.
- Do not use controller concerns as local file-folders for one controller only.
- Do not keep adding root-level partials after a screen subtree already exists.
- Do not let deep partials reach into `params` or associations when explicit state can be passed once.
- Do not forget shared helpers when refactoring routes; a stale polymorphic helper can break a page before the newly extracted controller code even runs.

## View Defaults

- Follow the existing Slim plus Turbo patterns in this repo.
- Keep Turbo Stream templates at the resource root when they are endpoint-owned.
- Prefer explicit nested render paths once a subtree exists.
