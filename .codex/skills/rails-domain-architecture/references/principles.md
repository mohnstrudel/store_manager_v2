# Rails Domain Architecture Principles

Use this file for the non-obvious model-layer rules in this repo.

## Core Rules

- Treat `app/models` as the home for the domain, not just Active Record tables.
- Keep the base model file short as a composition root.
- Put aggregate-owned behavior under `app/models/<model>/<capability>.rb`.
- Reserve `app/models/concerns` for true cross-model behavior.
- Prefer model-area workflow objects such as `app/models/product/upsert.rb` when the workflow still belongs to one aggregate.
- Prefer named scopes and preload scopes over controller-built SQL or tiny query wrappers.

## What Codex Often Gets Wrong

- Do not extract a single-model capability out of the model layer just because the model has many methods.
- Do not move composable scopes into query objects unless the query is a first-class subsystem.
- Do not move stable cross-process representations out of the model layer just because they return strings.
- Do not flatten association-local behavior into detached manager objects if it belongs to one relationship.
- Do not assume callbacks are bad when they are maintaining one local concept.

## Base Model Boundary

- The base file should mostly show:
  - includes
  - top-level associations
  - validations
  - broad ordering or preload scopes
  - light model wiring
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

## Concerns

- Use `app/models/concerns` only when the same behavior really applies to multiple models.
- Concerns may define contracts, hooks, and callbacks when they are acting as small internal frameworks.
- Do not move single-model business rules into concerns just to keep the base model shorter.

## Model-Area Objects

- Keep model-adjacent POROs in `app/models` when they are part of the domain language.
- Good examples:
  - workflow objects
  - payload builders
  - integration importers or parsers
  - query subsystems with real identity

## Representation Boundary

- Screen-only wording belongs at the edge.
- Reusable representations that cross jobs, parsers, sync flows, exports, or notifications can stay near the model.
- Stable title builders usually belong in a capability such as `app/models/product/titling.rb`, not in helpers.

## Placement Shortcuts

- one aggregate owns the invariant -> `app/models/<model>/<capability>.rb`
- one aggregate owns a bigger workflow -> `app/models/<model>/<workflow>.rb`
- shared cross-model behavior -> `app/models/concerns/<concern>.rb`
- repeated read shape -> named scope on the owning model
- multi-aggregate or external orchestration -> a focused object in an explicit `app/models/<namespace>/` home

## Refactor Stance

- Treat current placement as evidence, not as architecture worth preserving.
- Name explicit target files instead of saying “extract an object”.
- Move one coherent slice at a time.
