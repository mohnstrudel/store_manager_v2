---
name: rails-domain-architecture
description: Design or refactor the backend side of Ruby on Rails codebases toward a model-centric architecture that keeps domain logic, associations, scopes, callbacks, state transitions, and test ownership close to the owning models. Use when planning backend file layout, deciding between models, concerns, and query objects, organizing scopes, extracting capabilities into app/models/<model>/, designing request boundaries, or building reusable backend testing strategies for rich Rails domains. Do not use this skill for React or other frontend UI work; use `frontend-architecture` instead.
---

# Rails Domain Architecture

## Quick Start

- In this repo, treat `rails-domain-architecture` as the default starting skill for backend and domain work.
- For React pages, shared components, hooks, browser-side widgets, and frontend tests, switch to `frontend-architecture` instead of trying to force the backend skill to fit.

## Default Workflow

1. Choose the request boundary and access-scoped entry relation.
2. Choose the owning model and keep the base model file short as the composition root.
3. Put associations, scopes, callbacks, predicates, and commands for one business concept in `app/models/<model>/<capability>.rb`.
4. Use `app/models/concerns` only for behavior reused across multiple models.
5. Prefer rich, intention-revealing model APIs over controller-shaped workflow methods or generic service wrappers.
6. Keep scopes composable, relation-returning, and named after business concepts.
7. Use named preload scopes for repeated read shapes.
8. Keep controllers thin: load the starting relation, compose named scopes, and call model commands.
9. Keep rendering at the edge: helpers for presentation, Jbuilder or serializers for JSON.
9a. If the change is frontend UI work, switch to `frontend-architecture` so backend rules do not bleed into component design.
9b. For risky browser-side or visual work that still touches backend contracts, add focused feature specs that encode the rendered behavior.
10. Keep jobs thin and let model-adjacent objects own workflow rules.
11. Keep tests aligned with ownership: model capability tests at the domain seam, integration tests at the request seam, and system tests only for the highest-risk end-to-end flows.
12. Introduce query objects only when the query becomes a first-class subsystem such as saved filters, full-text search, reporting, or adapter-specific search backends.
13. Keep orchestration, importers, parsers, payloads, and workflow objects in `app/models` namespaces when they are still part of the domain language.
14. Preserve deliberate advanced model patterns: concern contracts, association-proxy APIs, event fan-out, lifecycle gates, and domain-owned representations.
15. Favor business verbs such as `publish`, `move_to`, `link_inventory`, or `sync_store_references` over form-shaped names such as `process_form` or `handle_update`.
16. Reach for a service object only when ownership is genuinely cross-aggregate, infrastructure-heavy, or not naturally expressible as one model-facing API.
18. When a non-CRUD controller action starts to feel like its own concept, prefer a small nested resource controller before adding another member or collection action to a broad controller.
19. Use controller scoping concerns such as `ProductScoped` or `SaleScoped` for repeated boundary loading when several small controllers share the same resource seam.
19a. “Shared” includes a namespaced controller family; do not create one-off concerns just to split one broad controller.
20. Treat command-style endpoints as write resources: prefer `POST`, `PATCH`, or `DELETE` resource routes over `GET` links for actions such as pulls, links, moves, or webhook confirmations.

## Placement Heuristics

- Use `app/models/<model>/<capability>.rb` when one model owns the invariant and the feature needs both reads and writes.
- Use `app/models/concerns/<concern>.rb` when the same behavior truly applies to multiple models.
- Use `app/models/<subsystem>/` objects when the subsystem has its own lifecycle, persistence, params, or backend.
- Use controller concerns for request setup, scoping, and policy, not for domain rules.
- Use namespaced controllers and base controllers to separate public, private, settings, and workflow surfaces.
- Keep existing project conventions when they are already strong; do not preserve weak or mixed legacy placement just because it already exists.

## Deliverables

- Propose file placement before large refactors.
- Preserve request-scoped context such as tenant, account, user, and timezone.
- Preserve authorization and tenancy boundaries in the starting relation.
- Avoid `default_scope` and controller-built SQL when named scopes can express the intent.
- Prefer business names such as `active`, `archived`, `awaiting_review`, and `preloaded` over transport-layer names.
- Add or preserve tests at the same ownership seam as the code: capability, request, edge rendering, or async transport.
- For legacy refactors, propose explicit target files under `app/models/<model>/...` rather than vague “extract helper object” guidance.
