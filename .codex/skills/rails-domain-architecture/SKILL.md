---
name: rails-domain-architecture
description: Design or refactor Ruby on Rails codebases toward a model-centric architecture that keeps domain logic, associations, scopes, callbacks, state transitions, and test ownership close to the owning models. Use when planning Rails file layout, deciding between models, concerns, query objects, and services, organizing scopes, extracting capabilities into app/models/<model>/, designing request boundaries, or building reusable testing strategies for rich Rails domains.
---

# Rails Domain Architecture

## Quick Start

- Read `references/principles.md` before proposing a new Rails architecture or refactoring an existing one.
- Read `references/advanced-model-patterns.md` when the codebase relies on rich concerns, callbacks, event fan-out, association proxy APIs, or model-owned representations.
- Read `references/full-stack-architecture.md` when the task spans routes, controllers, views, helpers, jobs, mailers, channels, or request context.
- Read `references/jobs-architecture.md` when the task is about Active Job, recurring work, queue design, retries, or moving logic into or out of background jobs.
- Read `references/controllers-and-request-refactors.md` when refactoring fat controllers or unclear request boundaries.
- Read `references/views-and-edge-refactors.md` when presentation logic is scattered across models, controllers, helpers, JSON builders, or JavaScript.
- Read `references/presentation-methods-without-presenters.md` when models contain many string-building or summary methods and you need to sort them without introducing presenters.
- Read `references/model-file-style.md` when you are cleaning up model file order, grouping, or cosmetics and want a consistent Fizzy-style layout.
- Read `references/jobs-refactors.md` when legacy jobs or scheduler code hide domain ownership.
- Read `references/testing-refactors.md` when tests need to move with new ownership seams after a refactor.
- Read `references/testing-architecture.md` when the task is about test strategy, test placement, fixtures, system vs integration coverage, or preserving architecture during refactors.
- Read `references/refactor-playbook.md` when migrating controller SQL, fat service objects, or ad hoc queries into reusable model structure.
- Start by identifying the request boundary, the owning model, and whether the work is a domain capability, a cross-cutting concern, a first-class query subsystem, or an orchestration service.
- Treat legacy file placement as evidence to analyze, not as architecture to preserve. Keep only the parts that are coherent.

## Default Workflow

1. Choose the request boundary and access-scoped entry relation.
2. Choose the owning model and keep the base model file short as the composition root.
3. Put associations, scopes, callbacks, predicates, and commands for one business concept in `app/models/<model>/<capability>.rb`.
4. Use `app/models/concerns` only for behavior reused across multiple models.
5. Keep scopes composable, relation-returning, and named after business concepts.
6. Use named preload scopes for repeated read shapes.
7. Keep controllers thin: load the starting relation, compose named scopes, and call model commands.
8. Keep rendering at the edge: helpers for presentation, partials for HTML, Jbuilder or serializers for JSON, Turbo Stream templates for incremental updates.
9. Keep jobs thin and let model-adjacent objects own workflow rules.
10. Keep tests aligned with ownership: model capability tests at the domain seam, integration tests at the request seam, and system tests only for the highest-risk end-to-end flows.
11. Introduce query objects only when the query becomes a first-class subsystem such as saved filters, full-text search, reporting, or adapter-specific search backends.
12. Introduce service objects only when coordinating multiple aggregates, external APIs, or side effects that do not belong to one model capability.
13. Preserve advanced model patterns when they are deliberate: concern contracts, association-proxy APIs, event fan-out, lifecycle gates, and domain-owned external representations are valid design choices.

## Placement Heuristics

- Use `app/models/<model>/<capability>.rb` when one model owns the invariant and the feature needs both reads and writes.
- Use `app/models/concerns/<concern>.rb` when the same behavior truly applies to multiple models.
- Use `app/models/<subsystem>/` objects when the subsystem has its own lifecycle, persistence, params, or backend.
- In legacy apps, default to creating a folder under the owning model in `app/models/<model>/` before reaching for `app/services`.
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
- For legacy refactors, propose explicit target files under `app/models/<model>/...` rather than vague “extract service” guidance.
- Keep the guidance reusable; do not depend on a specific repository layout unless the user asks for repo-local advice.

## References

- Read `references/principles.md` for the default architecture rules and model layout.
- Read `references/advanced-model-patterns.md` for non-obvious model-centric patterns that generic Rails guidance often misses.
- Read `references/full-stack-architecture.md` for request flow, routing, controllers, views, jobs, and edge-layer design.
- Read `references/jobs-architecture.md` for queue, retry, resumability, scheduling, and thin-job design guidance.
- Read `references/controllers-and-request-refactors.md` for explicit destination rules when moving controller logic back to request boundaries, model workflows, and named scopes.
- Read `references/views-and-edge-refactors.md` for explicit destination rules when moving screen logic to partials, helpers, Jbuilder, and Turbo templates.
- Read `references/presentation-methods-without-presenters.md` for rules that distinguish screen-only model methods from true domain representations without defaulting to presenters.
- Read `references/jobs-refactors.md` for explicit destination rules when slimming jobs and moving workflow logic to model-area collaborators.
- Read `references/testing-refactors.md` for explicit test-file targets after moving ownership seams.
- Read `references/testing-architecture.md` for test ownership, fixtures, request/system test boundaries, and testing patterns for rich model layers.
- Read `references/refactor-playbook.md` for a decision matrix and a migration sequence.
