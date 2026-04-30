---
name: rails-domain-architecture
description: Design or refactor Ruby on Rails codebases toward a model-centric architecture that keeps domain logic, associations, scopes, callbacks, state transitions, and test ownership close to the owning models. Use when planning Rails file layout, deciding between models, concerns, and query objects, organizing scopes, extracting capabilities into app/models/<model>/, designing request boundaries, or building reusable testing strategies for rich Rails domains.
---

# Rails Domain Architecture

## Quick Start

- In this repo, treat `rails-domain-architecture` as the default starting skill for most app work. Add narrower skills such as `shopify` only when the task clearly touches that subsystem.
- Read `references/task-router.md` first for the smallest useful reference set.
- Read `references/principles.md` before proposing a new Rails architecture or refactoring an existing one.
- Read `references/full-stack-architecture.md` when the task spans routes, controllers, views, helpers, jobs, mailers, channels, or request context.
- Read `references/jobs-architecture.md` when the task is about Active Job, recurring work, queue design, retries, or moving logic into or out of background jobs.
- Read `references/screen-first-view-pattern.md` for the repo's single view-organization guide, including both the simple CRUD baseline and the expanded screen-first shape.
- Read `references/testing-architecture.md` when the task is about test strategy, test placement, fixtures, system vs integration coverage, or preserving architecture during refactors.
- Start by identifying the request boundary, owning model, and whether the work is domain capability, cross-cutting concern, query subsystem, or orchestration.
- Treat legacy file placement as evidence, not architecture to preserve.

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
9a. Keep Stimulus narrow: server renders structure and view data; Stimulus owns one widget's interaction state and loading transitions.
9b. For risky JavaScript or visual work, add focused feature specs that encode the rendered behavior.
10. Keep jobs thin and let model-adjacent objects own workflow rules.
11. Keep tests aligned with ownership: model capability tests at the domain seam, integration tests at the request seam, and system tests only for the highest-risk end-to-end flows.
12. Introduce query objects only when the query becomes a first-class subsystem such as saved filters, full-text search, reporting, or adapter-specific search backends.
13. Keep orchestration, importers, parsers, payloads, and workflow objects in `app/models` namespaces when they are still part of the domain language.
14. Preserve deliberate advanced model patterns: concern contracts, association-proxy APIs, event fan-out, lifecycle gates, and domain-owned representations.
15. Favor business verbs such as `publish`, `move_to`, `link_inventory`, or `sync_store_references` over form-shaped names such as `process_form` or `handle_update`.
16. Reach for a service object only when ownership is genuinely cross-aggregate, infrastructure-heavy, or not naturally expressible as one model-facing API.
17. Keep small params normalization in controllers, but when one form starts needing several normalization helpers or failed-submit rebuilding, extract narrow form objects such as `FormPayload` or `FormRehydrator` under the owning model namespace instead of growing a generic service layer.
18. When a non-CRUD controller action starts to feel like its own concept, prefer a small nested resource controller before adding another member or collection action to a broad controller.
19. Use controller scoping concerns such as `ProductScoped` or `SaleScoped` for repeated boundary loading when several small controllers share the same resource seam.
19a. “Shared” includes a namespaced controller family; do not create one-off concerns just to split one broad controller.
20. Treat command-style endpoints as write resources: prefer `POST`, `PATCH`, or `DELETE` resource routes over `GET` links for actions such as pulls, links, moves, or webhook confirmations.
21. Collection-level workflows can also be first-class controllers; extraction is not only for member actions.
22. After extracting a controller concept, update the route consumers too: helpers, shared buttons, Turbo widgets, and feature specs should follow the new route shape instead of reconstructing paths by guesswork.
23. In JavaScript, prefer obvious method names over generic `render`, `sync`, or option-heavy helpers when the widget is small.
24. For UI and Stimulus refactors, cover the user-visible contract at the widget seam.
25. Do not make nested attributes the default way to model child-resource editing. When a child entity has its own create, update, or destroy lifecycle, prefer a small child-resource request surface over one giant parent form.
26. Keep composite parent-plus-children forms as explicit exceptions. Use them only when the screen is truly one atomic submit and splitting the child interactions into separate endpoints would make the UX or invariants worse.

## Placement Heuristics

- Use `app/models/<model>/<capability>.rb` when one model owns the invariant and the feature needs both reads and writes.
- Use `app/models/concerns/<concern>.rb` when the same behavior truly applies to multiple models.
- Use `app/models/<subsystem>/` objects when the subsystem has its own lifecycle, persistence, params, or backend.
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

## References

Use `references/task-router.md` first, then only the reference that matches the task: model principles, full-stack request flow, jobs, screen-first views, or testing.
