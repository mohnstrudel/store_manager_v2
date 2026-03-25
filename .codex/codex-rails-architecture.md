# Codex Rails Architecture Guide

Use this document as a reusable architecture brief for Codex on other Rails projects. It is based on a close reading of a production-style Rails app that organizes the whole stack around domain ownership, request context, server-rendered views, and thin async wrappers.

## AGENTS.md Snippet

```md
# Rails Architecture

Design Rails apps around domain ownership and request-scoped boundaries, with domain-adjacent code living in `app/models`.

- Treat each base model file as a composition root. Keep it short: core associations, validations, a few broad ordering or preload scopes, and included capability modules.
- Prefer model capability modules under `app/models/<model>/` for cohesive business concepts that own associations, scopes, callbacks, commands, and predicates.
- Reserve `app/models/concerns` for true cross-cutting behavior reused by multiple models. Do not hide single-model domain logic there.
- Use cross-cutting concerns as small internal frameworks when appropriate: define a clear contract, required methods, and override points rather than dumping helpers into a mixin.
- Use `app/models` for more than Active Record tables. It may also contain form objects, query subsystems, payload builders, workflow objects, value objects, import/export helpers, and other domain-adjacent POROs.
- Put scopes beside the state and associations they depend on. Name them after business states and user-visible concepts, not SQL details.
- Prefer starting reads from permission-scoped or tenant-scoped relations such as `Current.user.accessible_records` instead of global model entry points.
- Use named preload scopes for common read shapes used by controllers, views, jobs, and APIs.
- Avoid `default_scope`.
- Introduce dedicated query objects only when the query becomes a first-class concept such as saved filters, full-text search, reporting, adapter-specific backends, or multi-step import/export lookups.
- Keep coordination, external API mappings, file workflows, and long-running domain processes in explicit `app/models/<namespace>/` objects when they remain part of the product's domain language.
- Use `Current` for request-scoped context such as account, user, identity, session, timezone, platform, and tracing metadata. Set it at the request boundary and rehydrate it in jobs or channels when needed.
- Use association proxy extensions when a collection has its own commands, such as `grant_to`, `revoke_from`, or `revise`, instead of inventing a detached object for collection-local behavior.
- Treat domain events as a first-class spine when many side effects need the same source of truth. Timelines, notifications, webhooks, and system comments can all fan out from one event model.
- Keep routes and controller namespaces aligned with access surfaces and workflows: private, public, account settings, personal settings, nested child resources, and state transitions.
- Keep controllers thin. Let controllers load records through scoped relations, compose named scopes, and call model commands.
- Use controller concerns for loading context, scoping records, and request policy. Keep business rules out of controller concerns.
- Prefer server-rendered HTML as the source of truth in Rails apps like this. Use Turbo Frames and Turbo Streams for incremental updates instead of pushing domain behavior into JavaScript.
- Organize view partials by screen and display variant. Put markup and presentation branching in views and helpers, not in models.
- Keep JSON at the edge with Jbuilder partials or another explicit rendering layer. Do not let controllers hand-build JSON hashes for large responses.
- Keep helpers presentation-only: HTML wrappers, labels, button helpers, route helpers, and display formatting.
- Allow domain-owned external representations inside model namespaces when they are true product interfaces, such as exports, notification payloads, prompts for LLMs, or webhook payload generation.
- Keep Stimulus controllers focused on interaction, navigation, pagination, forms, and progressive enhancement. Do not move domain state machines into front-end code.
- Keep jobs thin. Jobs should usually call one model command, subsystem object, or mailer entry point.
- Let domain models or model-adjacent collaborators decide recipients, payloads, and workflow behavior; let mailers and views handle rendering.
- Accept callbacks when they are local to one capability and maintain that same concept's read models, ledgers, broadcasts, or fan-out. Do not ban callbacks reflexively.
- If a technical subsystem is user-visible, model it as a domain abstraction. Storage quotas, notification bundles, import/export manifests, or search indexes may belong in `app/models` even if they touch infrastructure.
- Keep tests aligned with ownership. Test model capabilities at the domain seam, controller behavior with integration tests, and HTML, JSON, or Turbo output at the edge.
- Use `fresh_when`, `etag`, and fragment caching at the edges for expensive read paths.
```

## Anti-Default LLM Checklist

Before refactoring a Rails codebase, check these first:

- Do not extract a single-model capability out of the model layer just because the model has many methods.
- Do not move composable scopes into query objects unless the query is a first-class subsystem.
- Do not replace a clear concern contract with vague helper modules.
- Do not flatten association-proxy APIs into detached manager objects if the behavior belongs to one relationship.
- Do not remove callbacks that are maintaining adjacent read models, events, broadcasts, or ledgers unless they are actually surprising or unsafe.
- Do not treat every non-ActiveRecord object in `app/models` as misplaced. It may be a form object, payload builder, workflow object, or query subsystem.
- Do not push product-facing representations such as exports, prompts, or webhook payloads into views/helpers if they are reused as domain interfaces.
- Do not move server-rendered interaction flows into JavaScript when Turbo and partial rendering already express them cleanly.
- Do not rebuild tenancy or authorization filters ad hoc in controllers if a scoped entry relation can own them.
- Do not turn thin jobs into detached workflow containers; keep the job as transport unless the workflow truly belongs in a named model-layer object.
- Do not collapse rich capability tests into generic object tests when the model already owns the concept.

## Layer Placement

- Put single-model business capabilities in `app/models/<model>/<capability>.rb`.
- Put true cross-model behavior in `app/models/concerns/<concern>.rb`.
- Put query subsystems in `app/models/<subsystem>/`.
- Put form objects, payload builders, and workflow objects in `app/models/<namespace>/` when they are part of the domain language.
- Put collection-local behavior on association proxies when the collection itself has a meaningful API.
- Put request setup in middleware, base controllers, and controller concerns.
- Put authorization- or tenancy-scoped entry relations on `User`, `Account`, or another true boundary object.
- Put public/read-only variants behind namespaced base controllers and layouts.
- Put HTML rendering in ERB partials and JSON rendering in Jbuilder partials.
- Put side-effect delivery in jobs and mailers, while keeping recipient and payload rules near the domain.

## Request Flow Rules

- Set `Current` attributes early, before business code runs.
- If the app is multi-tenant, extract tenant context at the routing or middleware boundary instead of scattering `where(account_id: ...)` through controllers.
- Reconstruct request context explicitly in jobs, channels, and mailers when they need account- or user-aware behavior.
- Use controller concerns for repeated loading patterns such as `BoardScoped`, `CardScoped`, `FilterScoped`, and request policies such as authentication or timezone selection.

## Controller Rules

- Keep controllers as orchestration for one request.
- Load records through access-scoped associations such as `Current.user.boards` or `Current.user.accessible_cards`.
- Compose named relations rather than embedding SQL or large branching trees in controllers.
- Keep state transitions explicit with focused endpoints such as `publish`, `close`, `triage`, `pin`, or `activate`.
- Support multiple formats only at the edge: `html`, `json`, and `turbo_stream` responses can coexist, but they should call the same domain operations.

## View and API Rules

- Use nested partial trees to reflect display variants such as preview, detail, tray, menu, or public view.
- Put conditional presentation and HTML-building helpers in helpers, not in the model layer.
- Use Turbo Frames and Turbo Stream templates for partial page refreshes.
- Keep JSON rendering in explicit templates or serializers so the response shape remains discoverable and cacheable.
- If the app is server-rendered, let JavaScript enhance the UI rather than define the core business flow.

## Async and Workflow Rules

- Keep jobs small and restartable where possible.
- Let scheduled tasks invoke model class methods or focused jobs, not giant scheduler scripts.
- Put long-running workflow logic in model-adjacent subsystem objects if it belongs to the domain, especially for imports, exports, search indexing, and notification batching.
- Keep mailers thin and driven by already-prepared domain data.
- Use notifier or payload objects when recipient selection or payload generation has enough branching to deserve its own object, but still belongs to one domain concept.

## Refactor Sequence

1. Map the request boundary: tenant, account, user, public access, and format.
2. Find the true starting relation and move access rules there.
3. Group model behavior by business capability and extract `app/models/<model>/<capability>.rb` modules.
4. Move controller-built relation logic into named scopes and preload scopes.
5. Move view-specific formatting out of models and into helpers, partials, Jbuilder, or small presenter-like objects.
6. Move async delivery into thin jobs that call model or subsystem methods.
7. Introduce query objects or namespaced model-layer collaborators only when subsystem complexity genuinely requires them.

## Do Not Copy Blindly

- Keep existing conventions when a project already has a strong architecture.
- Adapt the view guidance if the project uses ViewComponent, Phlex, GraphQL, or a SPA front end.
- Do not “modernize” a model-centric design away from `app/models` just because generic Rails advice says to.
- Use these rules to simplify navigation and ownership, not to force every project into identical folders.
- Prefer the smallest change that makes the next maintainer understand where new code belongs.
