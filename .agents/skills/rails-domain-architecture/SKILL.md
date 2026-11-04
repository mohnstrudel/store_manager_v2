---
name: rails-domain-architecture
description: Design or refactor the backend side of Ruby on Rails codebases toward a model-centric architecture with clear domain boundaries, behavior owners, invariants, state sources, write paths, and test ownership. Use when planning backend file layout, deciding between models, concerns, and query objects, organizing scopes, extracting capabilities into app/models/{model}/, designing request boundaries, changing domain behavior or derived data, or building reusable backend testing strategies for rich Rails domains. Do not use this skill for React or other frontend UI work; use `frontend-architecture` instead.
---

# Rails Domain Architecture

## Usage

- Use this skill while planning to inspect Rails code and draft the Domain Contract, and keep it active through implementation and validation.
- Treat this as the default architecture skill for backend and domain work in this repo.
- For React components, hooks, browser state, and frontend tests, use `frontend-architecture` instead.
- Load `rails-testing` when work touches request specs, Rails test infrastructure, or shared Ruby contracts; it supplies the repository-specific rules behind the Tests label below.

## Required Domain Contract

Before planning a behavior-bearing backend change or a refactor that affects or calls into question ownership, authority, state, or boundaries, write every label. Write `Not applicable — <reason>` when a label does not apply. When collaborative planning loads `architecture-review.md`, incorporate its relevant lifecycle and public-contract decisions through these labels instead of creating a separate Rails checklist:

- **Owner and boundary:** Name the owning model, domain, or subsystem and the authorized request entry relation. A namespace or file location alone is not a boundary.
- **State:** Classify affected values as authoritative, external, or derived. Name each source and permitted writer.
- **Invariants:** Name the rules that must hold and their database, domain, authorization, transaction, or locking enforcement. Use database constraints whenever they can express the rule.
- **Commands:** Name the business-facing write APIs. Route invariant-bearing writes through the owner. At request boundaries, pass scoped records or relations into commands instead of reloading them globally.
- **Inspection and recovery:** Explain how to inspect current state and relevant history, detect drift, and safely repair or recompute it.
- **Tests:** Cover the domain and request seams, including invalid, unauthorized, stale, and concurrency-sensitive scenarios where relevant. Request specs own the Rails-to-Inertia contract; frontend component tests do not replace them. See `rails-testing` for the Rails test boundary and infrastructure.

## Implementation Path

1. Inspect current behavior, persistence, writers, callbacks, request boundaries, and tests. Treat current placement as evidence, not proof of correct ownership.
2. Start from an authorized, access-scoped relation and call the owning domain command.
3. Place code by ownership and cohesion:
   - Use `app/models/<model>/<capability>.rb` when behavior forms one coherent capability of a record or relation; do not extract a module only to shorten a model. Extend the capability that already serves the same payload instead of adding a near-identical sibling, and name capabilities for exactly what they hold.
   - Name a capability for what the record can be (`Taggable`, `Linkable`, `Titled`, `Revisable`) or for its business area (`Settlement`), never for a screen, job, or mechanism (`Listing`, `Editing`, other `*ing` names); `Project/CapabilityModuleName` enforces this, and `AllowedNames` lists business nouns ending in `ing`.
   - Keep the base model file to includes, core associations, validations, callbacks, and preload scopes. Name a preload scope `preloaded` for the model's richest shape or `with_<what it loads>` for a narrower one; keep `for_<noun>` for filters that take a parameter.
   - Declare an association inside the capability whose behavior it serves. A reference from a base preload scope, a search, or a resource does not make it core. Keep it in the base file only when its `dependent:` callback must run in a fixed order relative to a callback declared there: Product keeps `variants` beside `before_destroy :destroy_variant_assignments`, which must run first.
   - `belongs_to default:` is a `before_validation` that assigns only when the reader is nil and is skipped by `save(validate: false)`; use it for plain defaults, never in place of an overwrite.
   - Use `app/models/concerns` only for behavior shared by multiple models.
   - Use a namespaced object when it has independent inputs, results, collaborators, or adapter responsibility.
   - Reserve query objects for first-class read subsystems.
   - Put plain Ruby objects in `app/models` and name them for what they are (`Client`, `Parser`, `Importer`); there is no `app/services` category. External API transport lives under its integration namespace, such as `app/models/shopify/api/client.rb`.
4. Keep boundaries explicit: controllers own parameters, authorization, scoped loading, responses, and rendering; jobs own async scheduling, delivery, and retries; integration clients own external protocols; parsers translate external data; importers map it and call domain commands. Domain commands remain the only invariant-bearing writers. Parsers and importers own store vocabulary (Shopify enums, Woo attribute names, gids); domain modules never decode payloads.
5. Name commands with business verbs, paired where an inverse exists (`deactivate` / `reactivate`); form saves are `record` (new record from a form) and `revise` (change from a form). Use `!` only when the same class defines the non-bang twin, not to mark raising or writing; `Project/BangWithoutCounterpart` enforces this. Rails' own bang methods (`save!`) are unaffected.
6. Keep reusable reads as named, relation-returning scopes with deliberate preload shapes. Write conditions with hash syntax, `where.missing`, `where.associated`, `merge`, or Arel predicates; keep an SQL string or `Arel.sql` only where Arel has no equivalent. Pair a state scope with its predicate (`linked?`, `empty?`), adding a missing twin only where code checks that state inline today. Keep fixed lists as frozen constants, not methods. Build Inertia props or JSON at the rendering edge without reconstructing domain data.
7. Build Inertia page props with Alba resources in `app/resources/`: one page resource per page (`Sales::IndexResource`) over a locals hash, rendered with `render_inertia "<Page>", serializer:, locals:`, composed from one shared resource per record shape (`SaleResource`, extended by `Sales::ListingResource`). Annotate every computed attribute with `typelize`; Typelizer generates `app/frontend/types/serializers/` and CI fails when it is stale, so regenerate with `bin/rails typelizer:generate` after changing a resource. Helpers hold only formatting used by resources and views.
8. Represent command endpoints as small resources using write HTTP verbs. Reuse controller scoping concerns only across a real controller family.

## Refactor Safety

- Preserve external values and provenance separately from business interpretation unless the application clearly owns the state.
- Give derived values one producer, named authoritative inputs, an idempotent recompute command, and a consistency check.
- Use `after_commit` for external effects such as notifications and jobs, not as the only mechanism that keeps authoritative or cached data correct.
- Use the simplest inspectable representation that satisfies the invariant; a value changing over time does not by itself justify another abstraction.
- Change the producer or contract when a consumer needs domain data; do not reconstruct it from nearby values, payloads, or side effects.
- Avoid parallel mechanics, facades, and compatibility adapters unless a migration requires them; document their removal condition.
