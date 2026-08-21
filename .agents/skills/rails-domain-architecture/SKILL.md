---
name: rails-domain-architecture
description: Design or refactor the backend side of Ruby on Rails codebases toward a model-centric architecture with clear domain boundaries, behavior owners, invariants, state sources, write paths, and test ownership. Use when planning backend file layout, deciding between models, concerns, and query objects, organizing scopes, extracting capabilities into app/models/{model}/, designing request boundaries, changing domain behavior or derived data, or building reusable backend testing strategies for rich Rails domains. Do not use this skill for React or other frontend UI work; use `frontend-architecture` instead.
---

# Rails Domain Architecture

## Usage

- Use `collaborative-planning` to run the planning process. During planning, use this skill to inspect Rails code and draft the Domain Contract; after approval, keep using it through implementation and validation.
- Treat this as the default architecture skill for backend and domain work in this repo.
- For React components, hooks, browser state, and frontend tests, use `frontend-architecture` instead.

## Required Domain Contract

Before planning a behavior-bearing backend change or a refactor that affects or calls into question ownership, authority, state, or boundaries, write every label. Write `Not applicable — <reason>` when a label genuinely does not apply. When collaborative planning loads `architecture-review.md`, incorporate its relevant lifecycle and public-contract decisions through these labels instead of creating a separate Rails checklist:

- **Owner and boundary:** Name the owning model, domain, or subsystem and the authorized request entry relation. A namespace or file location alone is not a boundary.
- **State:** Classify affected values as authoritative, external, or derived. Name each source and permitted writer.
- **Invariants:** Name the rules that must hold and their database, domain, authorization, transaction, or locking enforcement. Use database constraints whenever they can express the rule.
- **Commands:** Name the business-facing write APIs. Route invariant-bearing writes through the owner. At request boundaries, pass scoped records or relations into commands instead of reloading them globally.
- **Inspection and recovery:** Explain how to inspect current state and relevant history, detect drift, and safely repair or recompute it.
- **Tests:** Cover the domain and request seams, including invalid, unauthorized, stale, and concurrency-sensitive scenarios where relevant. Request specs own the Rails-to-Inertia contract; frontend component tests do not replace them.

## Implementation Path

1. Inspect current behavior, persistence, writers, callbacks, request boundaries, and tests. Treat current placement as evidence, not proof of correct ownership.
2. Start from an authorized, access-scoped relation and call the owning domain command.
3. Place code by ownership and cohesion:
   - Use `app/models/<model>/<capability>.rb` when behavior forms one coherent capability of a record or relation; do not extract a module merely to shorten a model.
   - Use `app/models/concerns` only for behavior genuinely shared by multiple models.
   - Use a namespaced object when it has independent inputs, results, collaborators, or adapter responsibility.
   - Reserve query objects for first-class read subsystems and services for infrastructure-heavy or genuinely cross-domain work.
4. Keep boundaries explicit: controllers own parameters, authorization, scoped loading, responses, and rendering; jobs own async scheduling, delivery, and retries; integration clients own external protocols; parsers translate external data; importers map it and call domain commands. Domain commands remain the only invariant-bearing writers.
5. Keep reusable reads as named, relation-returning scopes with deliberate preload shapes. Build Inertia props or JSON at the rendering edge without reconstructing domain data.
6. Represent command endpoints as small resources using write HTTP verbs. Reuse controller scoping concerns only across a real controller family.

## Refactor Safety

- Preserve external values and provenance separately from business interpretation unless the application clearly owns the state.
- Give derived values one producer, named authoritative inputs, an idempotent recompute command, and a consistency check.
- Use `after_commit` for external effects such as notifications and jobs, not as the only mechanism that keeps authoritative or cached data correct.
- Use the simplest inspectable representation that satisfies the invariant; a value changing over time does not by itself justify another abstraction.
- Change the producer or contract when a consumer needs domain data; do not reconstruct it from nearby values, payloads, or side effects.
- Avoid parallel mechanics, facades, and compatibility adapters unless a migration requires them; document their removal condition.
