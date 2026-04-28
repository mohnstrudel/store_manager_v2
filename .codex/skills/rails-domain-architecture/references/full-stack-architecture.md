# Rails Full-Stack Architecture

Use this file for the non-obvious request, controller, and presentation rules in this repo.

## Request Boundary

- Start from the real access boundary, not `Model.all`.
- Keep `Current` small. In this repo it stores `session` and delegates `user`.
- Rehydrate any request-dependent context explicitly in jobs or other async code when needed.

## Controllers

- Controllers are request adapters, not domain homes.
- Keep boundary loading, params normalization, format choice, and render or redirect decisions in controllers.
- Move long relation chains, aggregate-local transactions, business-state branching, payload logic, and hand-built HTML or JSON out of controllers.
- Prefer direct calls to intention-revealing model APIs before introducing a service layer between controllers and models.
- Small params normalization can stay in the controller. If one form needs several normalization helpers, nested-form translation, or failed-submit rebuilding, extract narrow form objects such as `Product::FormPayload` or `Product::FormRehydrator` under `app/models/<model>/`.
- If the controller action reads like a business verb, that verb probably belongs on the owning model or model-area object.
- When a side-effect action is really its own concept, prefer a dedicated resource controller over growing one large top-level controller.
- Use real write verbs for command endpoints. A pull, move, link, or webhook-confirm action should not hide behind `GET` just because the UI triggers it from a button or menu.
- Prefer small controller concerns for repeated resource seams such as `ProductScoped`, `SaleScoped`, or `WarehouseScoped`.
- Controller concerns should hold shared request-layer behavior, not one controller's private organization. “Shared” can mean app-wide or reused across one namespaced controller family.
- Inline Turbo interactions such as edit or cancel or update flows can still be resourceful; a small singular nested controller is often cleaner than `edit_foo`, `cancel_foo`, and `update_foo` actions on the parent controller.
- Collection workflows can be resourceful too when the concept lives at the collection or dashboard boundary.
- After route extraction, update helper code and shared UI primitives to use the new route contract. Generic helpers should prefer route helpers or correctly shaped polymorphic calls plus the right `turbo_method`, rather than assuming the old path shape still works.
- Do not default to `accepts_nested_attributes_for` or big nested payloads when the child entity has its own lifecycle. A small child-resource endpoint plus a focused form or button is usually the clearer request boundary.
- Keep nested or composite forms as an exception for truly atomic screens. If the child records can reasonably be created, edited, or removed independently, prefer separate request surfaces.

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
- child entity with its own create, update, or destroy interaction -> separate nested resource controller and small edge form
- one screen must submit a parent and several tightly coupled children together -> narrow form payload objects plus explicit rehydration if the form is genuinely composite

## Presentation Boundary

- Keep screen-specific logic at the edge.
- Do not add presenters by default.
- In this repo, presentation preparation usually lives in helpers and partials, not in a presenter layer.
- Use this sorting rule: one screen or response format belongs in helpers or templates; cross-process representations belong near the model; business identity or state text belongs in the model layer.
- If a Slim template starts assembling a small collection of view data for one widget or partial, prefer a helper before inventing a presenter.
- Keep that helper presentation-only: shaping labels, URLs, image variants, CSS classes, and screen-local flags is fine; domain rules and cross-process payloads are not.
- For interactive widgets, let the server render the structure and prepared view data first. Stimulus should usually own only interaction state, DOM class changes, and loading transitions.
- Avoid split ownership of one DOM node across multiple Stimulus controllers unless the separation is truly clear. If one widget owns one image or dialog state machine, prefer one controller to own that node end-to-end.
- Prefer small, literal Stimulus methods over abstract mini-frameworks.
- Because the agent cannot see the browser the way a human can, treat browser-level feature coverage as part of the design of non-trivial widgets. If the risk is visual or interactive, write the test at that seam instead of relying on code inspection alone.

## What Codex Often Gets Wrong

- Do not keep screen-specific text on the model or move true domain payloads into helpers.
- Do not leave controllers orchestrating aggregate workflows when one model command would say the business action clearly.
- Do not pass `ActionController::Parameters` into model APIs; translate request-shaped data at the edge or in a narrow form payload object.
- Do not use nested attributes, member actions, `GET` command endpoints, or one-off concerns as defaults when a real resource boundary exists.
- Do not add presenters, root-level partials, or deep `params` reads when helpers and explicit locals keep view preparation small.
- Do not make Stimulus fight server-rendered HTML or split one widget's lifecycle across multiple controllers without a clear boundary.
- Do not forget shared helpers and buttons when refactoring routes; stale route consumers often break before the new controller code runs.

## View Defaults

- Follow the existing Slim plus Turbo patterns in this repo.
- Keep Turbo Stream templates at the resource root when they are endpoint-owned.
- Prefer explicit nested render paths once a subtree exists.
