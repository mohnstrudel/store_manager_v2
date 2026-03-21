# Views and Edge Refactors

Use this guide when refactoring legacy Rails apps where presentation logic is scattered across models, controllers, helpers, JSON builders, and JavaScript.

## Core Read

- Presentation should live at the edge.
- Do not treat controller-built HTML or model-built screen text as the target architecture.
- Keep domain-owned representations near the model only when they are true product interfaces, not screen-specific rendering.

## Default Rule For Legacy View Refactors

- If the logic exists for one screen or one response format, move it toward:
- `app/views/`
- helpers
- Jbuilder or serializer templates
- Turbo Stream templates

- If the logic is reused as an export, payload, prompt, event description, or integration representation, it may belong under `app/models/<namespace>/`.

## 1. Default File Targets

HTML:
- `app/views/<resource>/show.html.erb`
- `app/views/<resource>/_container.html.erb`
- `app/views/<resource>/display/_preview.html.erb`
- `app/views/<resource>/display/_detail.html.erb`

Helpers:
- `app/helpers/<resource>_helper.rb`
- `app/helpers/pagination_helper.rb`
- `app/helpers/application_helper.rb`

JSON:
- `app/views/<resource>/show.json.jbuilder`
- `app/views/<resource>/_resource.json.jbuilder`

Turbo:
- `app/views/<resource>/create.turbo_stream.erb`
- `app/views/<resource>/update.turbo_stream.erb`
- `app/views/<resource>/destroy.turbo_stream.erb`

Layouts and access surfaces:
- `app/views/layouts/application.html.erb`
- `app/views/layouts/public.html.erb`

## 2. What To Move Out Of Models

- screen-only titles
- button labels
- CSS class helpers
- route-linked snippets
- HTML fragment builders
- response-specific JSON hashes

Common legacy examples:
- `*_for_select`
- `summary_for_<screen>`
- dropdown labels
- one-screen composite strings

## 3. What Can Stay Near The Domain

- export payloads
- webhook payloads
- notification payloads
- event descriptions reused across channels
- prompt text for AI-facing features

## 4. What To Move Out Of Controllers

- `safe_join`-heavy flash composition that really belongs in a helper or partial
- hand-built JSON structures
- branching that only changes presentation, not domain behavior
- repeated HTML snippet generation

## 5. Refactor Patterns

### Screen Variants

- Split large templates into partials by display variant such as:
- preview
- detail
- tray
- menu
- public

### JSON Responses

- Replace controller hash-building with explicit Jbuilder or serializer templates.
- Keep nested response shape discoverable in the view layer.

### Turbo Updates

- Use Turbo Stream templates for incremental updates instead of inline controller string building.

## 6. What Not To Preserve

- Do not preserve screen-specific formatting on the model just because it is currently called from many places.
- Do not preserve HTML generation in controllers when partials would communicate intent better.
- Do not preserve giant helper modules as dumping grounds; split by presentation concern if needed.

## 7. Anti-Default LLM Checklist

- Do not move domain payload builders into helpers if they are not screen-only.
- Do not keep screen-specific text in models “for reuse” when the reuse is only across templates.
- Do not jump to presenters as the default answer; first sort methods into helper, edge template, model, or model-adjacent representation.
- Do not push server-rendered flows into JavaScript when partials and Turbo already express them cleanly.
