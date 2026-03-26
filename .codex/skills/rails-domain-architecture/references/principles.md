# Rails Domain Architecture Principles

Use this file for the non-obvious model-layer rules in this repo.

## Core Rules

- Treat `app/models` as the home for the domain, not just Active Record tables.
- Keep the base model file short as a composition root.
- Put aggregate-owned behavior under `app/models/<model>/<capability>.rb`.
- Reserve `app/models/concerns` for true cross-model behavior.
- In the controller layer, reserve concerns for true shared request behavior, either cross-app or reused by a controller family around one seam.
- Prefer rich model APIs with business verbs over controller-shaped workflows and generic manager objects.
- Prefer model-area workflow objects such as `app/models/product/upsert.rb` when the workflow still belongs to one aggregate.
- When one form needs heavy request-shape translation, use small model-area form objects such as `app/models/product/form_payload.rb` or `app/models/product/form_rehydrator.rb` instead of teaching the aggregate about controller params.
- Prefer named scopes and preload scopes over controller-built SQL or tiny query wrappers.
- Do not make nested attributes the default architecture for child records. Prefer separate child-resource request surfaces when the child has an independent lifecycle.
- Keep composite parent-plus-children forms as explicit exceptions for true one-submit workflows, not as the baseline for all editing screens.

## What Codex Often Gets Wrong

- Do not extract a single-model capability out of the model layer just because the model has many methods.
- Do not default to a service object when a controller or job can call one clear model method directly.
- Do not move composable scopes into query objects unless the query is a first-class subsystem.
- Do not move stable cross-process representations out of the model layer just because they return strings.
- Do not flatten association-local behavior into detached manager objects if it belongs to one relationship.
- Do not assume callbacks are bad when they are maintaining one local concept.
- Do not leave domain methods named after forms or transport steps when the business action has a clearer name.
- Do not create a controller concern that is only a private refactor for one controller file; that usually means the logic belongs in private methods, a new controller, or the model layer.

## Base Model Boundary

- The base file should mostly show:
  - includes
  - top-level associations
  - validations
  - broad ordering or preload scopes
  - light model wiring
- The base file should read like the aggregate's table of contents.
- Move concept-heavy behavior out of the base file into capability modules.

## Capability Modules

- A capability module may own:
  - associations
  - scopes
  - callbacks
  - predicates
  - commands
  - small private helpers
- This is the default destination for one business concept on one aggregate.
- Capability modules may call each other through the aggregate when the API stays small and coherent.
- Prefer narrow concept modules over broad buckets such as `Editing` when a sharper business name exists.
- Name public methods after domain actions and states, not after screens, params hashes, or controller flows.

## Concerns

- Use `app/models/concerns` only when the same behavior really applies to multiple models.
- Concerns may define contracts, hooks, and callbacks when they are acting as small internal frameworks.
- Do not move single-model business rules into concerns just to keep the base model shorter.

## Model-Area Objects

- Keep model-adjacent POROs in `app/models` when they are part of the domain language.
- Good examples:
  - workflow objects
  - payload builders
  - form payload or rehydration objects for complex aggregate-owned forms
  - integration importers or parsers
  - query subsystems with real identity
- A separate object is a good fit when the behavior is cross-aggregate, adapter-specific, or would otherwise force one model to know too much about infrastructure.

## Representation Boundary

- Screen-only wording belongs at the edge.
- Reusable representations that cross jobs, parsers, sync flows, exports, or notifications can stay near the model.
- Stable title builders usually belong in a capability such as `app/models/product/titling.rb`, not in helpers.

## Placement Shortcuts

- one aggregate owns the invariant -> `app/models/<model>/<capability>.rb`
- one aggregate owns a bigger workflow -> `app/models/<model>/<workflow>.rb`
- one aggregate owns a complex form boundary -> `app/models/<model>/form_payload.rb` and, if needed, `app/models/<model>/form_rehydrator.rb`
- shared cross-model behavior -> `app/models/concerns/<concern>.rb`
- repeated read shape -> named scope on the owning model
- multi-aggregate or external orchestration -> a focused object in an explicit `app/models/<namespace>/` home
- controller or job needs one clear domain action -> call the model method directly before inventing a service
- non-CRUD endpoint is really its own resource -> add a small nested controller under `app/controllers/<parent>/...`
- collection-level command or Turbo endpoint is its own concept -> add a small collection resource controller under `app/controllers/<parent>/...`
- child create, update, or destroy action can stand alone -> give it its own nested endpoint instead of folding it into parent nested attributes
- parent and children truly must submit together -> keep the form composite, but isolate translation and rehydration in narrow model-area form objects
- several small controllers share the same loading seam -> add a scoped controller concern instead of repeating lookups
- several namespaced controllers share the same boundary helpers -> a controller-family concern is appropriate
- command triggered from the UI -> route it with `POST`, `PATCH`, or `DELETE` and update helpers to match the new resource path

## Refactor Stance

- Treat current placement as evidence, not as architecture worth preserving.
- Name explicit target files instead of saying “extract an object”.
- Move one coherent slice at a time.
- When refactoring, improve names as well as placement so the public model API sounds like the business domain.
