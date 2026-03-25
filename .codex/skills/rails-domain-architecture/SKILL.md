---
name: rails-domain-architecture
description: Design or refactor Ruby on Rails codebases toward a model-centric architecture that keeps domain logic, associations, scopes, callbacks, state transitions, and test ownership close to the owning models. Use when planning Rails file layout, deciding between models, concerns, and query objects, organizing scopes, extracting capabilities into app/models/<model>/, designing request boundaries, or building reusable testing strategies for rich Rails domains.
---

# Rails Domain Architecture

## Quick Start

- Read `references/task-router.md` first when the task starts as “build”, “add”, “refactor”, or “fix” and you need to choose the right files and references quickly.
- In this repo, treat `rails-domain-architecture` as the default starting skill for most app work. Add narrower skills such as `shopify` only when the task clearly touches that subsystem.
- Read `references/principles.md` before proposing a new Rails architecture or refactoring an existing one.
- Read `references/full-stack-architecture.md` when the task spans routes, controllers, views, helpers, jobs, mailers, channels, or request context.
- Read `references/jobs-architecture.md` when the task is about Active Job, recurring work, queue design, retries, or moving logic into or out of background jobs.
- Read `references/screen-first-view-pattern.md` for the repo's single view-organization guide, including both the simple CRUD baseline and the expanded screen-first shape.
- Read `references/testing-architecture.md` when the task is about test strategy, test placement, fixtures, system vs integration coverage, or preserving architecture during refactors.
- Start by identifying the request boundary, the owning model, and whether the work is a domain capability, a cross-cutting concern, a first-class query subsystem, or an orchestration object that still belongs in `app/models`.
- Treat legacy file placement as evidence to analyze, not as architecture to preserve. Keep only the parts that are coherent.

## Default Workflow

1. Choose the request boundary and access-scoped entry relation.
2. Choose the owning model and keep the base model file short as the composition root.
3. Put associations, scopes, callbacks, predicates, and commands for one business concept in `app/models/<model>/<capability>.rb`.
4. Use `app/models/concerns` only for behavior reused across multiple models.
5. Prefer rich, intention-revealing model APIs over controller-shaped workflow methods or generic service wrappers.
6. Keep scopes composable, relation-returning, and named after business concepts.
7. Use named preload scopes for repeated read shapes.
8. Keep controllers thin: load the starting relation, compose named scopes, and call model commands.
9. Keep rendering at the edge: helpers for presentation, partials for HTML, Jbuilder or serializers for JSON, Turbo Stream templates for incremental updates.
9a. Keep Stimulus controllers narrow and literal: let the server render structure and view data, and let Stimulus own only interaction state, DOM toggles, and loading transitions for one widget.
9b. Treat browser-level UI tests as part of the implementation for risky JavaScript work. When the agent cannot truly see the interface, focused feature specs are how it proves geometry, loading states, dialog behavior, and rendered interaction contracts instead of guessing.
10. Keep jobs thin and let model-adjacent objects own workflow rules.
11. Keep tests aligned with ownership: model capability tests at the domain seam, integration tests at the request seam, and system tests only for the highest-risk end-to-end flows.
12. Introduce query objects only when the query becomes a first-class subsystem such as saved filters, full-text search, reporting, or adapter-specific search backends.
13. Keep orchestration, importers, parsers, payloads, and workflow objects in `app/models` namespaces when they are still part of the domain language.
14. Preserve advanced model patterns when they are deliberate: concern contracts, association-proxy APIs, event fan-out, lifecycle gates, and domain-owned external representations are valid design choices.
15. Favor business verbs such as `publish`, `move_to`, `link_inventory`, or `sync_store_references` over form-shaped names such as `process_form` or `handle_update`.
16. Reach for a service object only when ownership is genuinely cross-aggregate, infrastructure-heavy, or not naturally expressible as one model-facing API.
17. Keep small params normalization in controllers, but when one form starts needing several normalization helpers or failed-submit rebuilding, extract narrow form objects such as `FormPayload` or `FormRehydrator` under the owning model namespace instead of growing a generic service layer.
18. When a non-CRUD controller action starts to feel like its own concept, prefer a small nested resource controller before adding another member or collection action to a broad controller.
19. Use controller scoping concerns such as `ProductScoped` or `SaleScoped` for repeated boundary loading when several small controllers share the same resource seam.
19a. In controllers, “shared” includes a namespaced controller family. A scoped concern is a good pattern when multiple small controllers around one seam need the same loading and response helpers.
19b. Do not create one-off controller concerns just to break up a single broad controller file. If the logic is not shared by multiple controllers, prefer private methods, another controller, or moving business logic into the model layer.
20. Treat command-style endpoints as write resources: prefer `POST`, `PATCH`, or `DELETE` resource routes over `GET` links for actions such as pulls, links, moves, or webhook confirmations.
21. Remember that collection-level workflows can also be first-class controllers such as `Purchases::MovesController`, `Purchases::ProductEditionsController`, or `Dashboard::LastOrdersPullsController`; extraction is not only for member actions.
22. After extracting a controller concept, update the route consumers too: helpers, shared buttons, Turbo widgets, and feature specs should follow the new route shape instead of reconstructing paths by guesswork.
23. In JavaScript, prefer obvious method names such as `showIndex`, `renderSelection`, or `startLoading` over generic `render`, `sync`, or option-heavy helpers when the widget is small. Optimize for “read at a glance.”
24. For UI and Stimulus refactors, add or update at least one browser-driven feature spec at the widget seam. The test should cover the user-visible contract that the agent cannot reliably inspect by eye.
25. Do not make nested attributes the default way to model child-resource editing. When a child entity has its own create, update, or destroy lifecycle, prefer a small child-resource request surface over one giant parent form.
26. Keep composite parent-plus-children forms as explicit exceptions. Use them only when the screen is truly one atomic submit and splitting the child interactions into separate endpoints would make the UX or invariants worse.

## Placement Heuristics

- Use `app/models/<model>/<capability>.rb` when one model owns the invariant and the feature needs both reads and writes.
- Use `app/models/concerns/<concern>.rb` when the same behavior truly applies to multiple models.
- Use `app/models/<subsystem>/` objects when the subsystem has its own lifecycle, persistence, params, or backend.
- In legacy apps, default to creating a folder under the owning model in `app/models/<model>/` before introducing any new top-level abstraction elsewhere.
- Use controller concerns for request setup, scoping, and policy, not for domain rules.
- Use namespaced controllers and base controllers to separate public, private, settings, and workflow surfaces.
- Use helpers and view partials for presentation decisions.
- Keep existing project conventions when they are already strong; do not preserve weak or mixed legacy placement just because it already exists.

## Deliverables

- Propose file placement before large refactors.
- Preserve request-scoped context such as tenant, account, user, and timezone.
- Preserve authorization and tenancy boundaries in the starting relation.
- Avoid `default_scope` and controller-built SQL when named scopes can express the intent.
- Prefer business names such as `active`, `archived`, `awaiting_review`, and `preloaded` over transport-layer names.
- Add or preserve tests at the same ownership seam as the code: capability, request, edge rendering, or async transport.
- For legacy refactors, propose explicit target files under `app/models/<model>/...` rather than vague “extract helper object” guidance.
- Keep the guidance reusable; do not depend on a specific repository layout unless the user asks for repo-local advice.

## References

- Read `references/task-router.md` first for a task-to-reference map covering new models, controllers, views, jobs, tests, and refactors in this repo.
- Read `references/principles.md` for the default architecture rules and model layout.
- Read `references/full-stack-architecture.md` for request flow, routing, controllers, views, jobs, and edge-layer design.
- Read `references/jobs-architecture.md` for queue, retry, resumability, scheduling, and thin-job design guidance.
- Read `references/screen-first-view-pattern.md` for the repo-local view organization guide, from simple CRUD resources up through section-heavy resources such as `sales` and `products`.
- Read `references/testing-architecture.md` for test ownership, fixtures, request/system test boundaries, and testing patterns for rich model layers.
