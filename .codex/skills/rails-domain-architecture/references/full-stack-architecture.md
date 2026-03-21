# Rails Full-Stack Architecture

Use this guide when the task spans more than models. It describes a reusable architecture for request flow, routing, controllers, views, background work, and front-end enhancement in a model-centric Rails app.

## 1. Start From Request Boundaries

- Identify the real boundaries first:
  - Tenant or account
  - Authenticated user or public visitor
  - HTML, JSON, or Turbo Stream response
  - Timezone or platform context

- Set this context early, ideally in middleware, a base controller, or a connection object.
- Use `Current` for request-scoped values such as account, user, identity, session, timezone, platform, request id, and request metadata.
- Rebuild the same context in jobs, channels, and mailers when their behavior depends on it.

## 2. Organize Routes by Access Surface and Workflow

- Let routes reflect the user's mental model and access surface.
- Good namespaces include:
  - `account` for tenant-wide settings
  - `my` for personal settings
  - `public` for unauthenticated or published resources
  - Nested resources for child objects under a true parent
  - Dedicated endpoints for state transitions such as `publish`, `close`, `activate`, `pin`, or `triage`

- Use `scope module:` or `namespace` to keep route structure and controller file layout aligned.
- Prefer focused mutation endpoints over giant update actions with many unrelated branches.

## 3. Use Base Controllers and Controller Concerns for Request Mechanics

- Put shared request policy in base controllers and controller concerns:
  - Authentication
  - Authorization
  - Tenant/account requirement
  - Timezone selection
  - Platform detection
  - Common scoping loaders such as `BoardScoped`, `CardScoped`, or `FilterScoped`

- Keep business logic out of controller concerns.
- Good controller concern jobs:
  - Set instance variables from scoped relations
  - Guard access
  - Parse or normalize request params
  - Set layout or response headers

## 4. Keep Controllers Thin and Relation-Oriented

- A controller action should usually do four things:
1. Load the starting relation or record from the correct boundary
2. Compose named scopes or preload scopes
3. Call a model command or subsystem object
4. Render or redirect in the requested format

- Prefer:

```ruby
def index
  set_page_and_extract_portion_from Current.user.accessible_orders.latest.preloaded
end
```

- Over:

```ruby
def index
  @orders = Order
    .joins(:memberships)
    .where(memberships: { user_id: Current.user.id })
    .where(account_id: Current.account.id)
    .includes(:customer, :line_items)
    .order(created_at: :desc)
end
```

- Controllers may support multiple formats, but the domain operation should stay shared across formats.

## 5. Keep Rendering at the Edge

- Let views and helpers own presentation.
- Organize partials by screen and display variant, not by database table alone.
- Typical variant folders:
  - `preview`
  - `detail`
  - `tray`
  - `menu`
  - `public`
  - `perma`

- Use helpers for:
  - HTML wrappers
  - Display labels
  - Button/link helpers
  - Route-linked snippets
  - Presentation-only CSS class logic

- Avoid putting markup construction and UI wording deep inside controllers.

## 6. Use Turbo and Stimulus as Progressive Enhancement

- For server-rendered apps, keep the server response as the source of truth.
- Use Turbo Frames and Turbo Stream templates for:
  - Partial refreshes
  - In-place create/update/destroy flows
  - Sidebar, tray, or dialog updates
  - Incremental pagination

- Keep Stimulus controllers focused on:
  - Navigation
  - Forms
  - Pagination
  - Dialogs
  - Copy-to-clipboard
  - Local UI state
  - Progressive enhancement

- Avoid duplicating core domain state transitions in JavaScript.

## 7. Keep JSON Explicit

- Put JSON rendering in Jbuilder partials or another explicit serializer layer.
- Keep JSON structure alongside the response templates instead of hand-building hashes across controllers.
- Reuse partials for nested JSON objects where that helps keep shape definitions discoverable.

This keeps:
  - HTML rendering in ERB
  - JSON rendering in Jbuilder
  - Domain behavior in models

## 8. Use Model-Adjacent Collaborators for Cross-Cut Domain Work

- Some objects are not Active Record models but still belong in `app/models/<namespace>/`.
- Good examples:
  - `Filter` and `Filter::Params`
  - `Search::Query`, `Search::Record`, `Search::Highlighter`
  - Notification payload objects
  - Event description objects
  - Import/export record-set classes
  - Signup form/workflow objects

- Use these when the concept has domain meaning and sits close to one bounded area.

## 8.5. Preserve Advanced Model-Centric Patterns

- Do not assume every callback should become a service.
- Do not assume every reusable mixin should become a concern full of helpers.
- Do not assume every relationship command should become a manager object.

- In model-centric Rails apps, valid advanced patterns include:
- concern contracts with required hooks
- association-proxy APIs
- event-centered fan-out
- domain-owned representations for exports, prompts, and payloads
- product-facing technical abstractions such as storage ledgers or notification bundles

## 9. Keep Jobs Thin and Domain-Driven

- Jobs should usually be wrappers around one domain operation:
- `perform(record) { record.notify_recipients }`
- `perform(import) { import.process }`
- `perform(delivery) { delivery.deliver }`

- Put workflow rules in models or subsystem objects, not in the job class.
- Use queue names for broad concerns such as `backend` and `webhooks`.
- For long-running workflows, make jobs resumable or chunked if the platform supports it.

## 10. Split Delivery Concerns Clearly

- Let domain events decide that something happened.
- Let notifier or payload objects decide:
  - Who should receive something
  - What payload or subject should be built
  - Whether the event is deliverable

- Let jobs handle async dispatch.
- Let mailers and templates handle rendering.

This keeps delivery logic understandable without forcing everything into one service class.

## 11. Use Caching at the Edge

- Use `fresh_when` and `etag` in controllers for expensive read actions.
- Use fragment caching in partials for repeated records or tree fragments.
- Cache rendered read shapes, not mutable controller internals.
- Bust cache via model timestamps or explicit dependencies where possible.

## 11.5. Keep Tests Aligned With Ownership

- Test model capabilities at the domain seam.
- Test controller and request behavior with integration tests that exercise routing, auth, tenancy, and rendering together.
- Test HTML, JSON, and Turbo Stream response contracts directly.
- Use system tests for a small set of high-risk end-to-end workflows, not for every branch.
- Treat time, `Current`, async delivery, and access boundaries as first-class test inputs.

## 12. Suggested File Layout

```text
app/
  controllers/
    application_controller.rb
    concerns/
    public/
    account/
    my/
    orders_controller.rb
    orders/
      closures_controller.rb
  models/
    order.rb
    order/
      fulfillable.rb
      searchable.rb
      broadcastable.rb
    concerns/
      searchable.rb
      notifiable.rb
    filter.rb
    filter/
      params.rb
      resources.rb
    search/
      query.rb
      record.rb
      highlighter.rb
  jobs/
    order/
      webhook_dispatch_job.rb
  views/
    orders/
      show.html.erb
      show.json.jbuilder
      _container.html.erb
      display/
        _preview.html.erb
        _detail.html.erb
```

## 13. Decision Rules

- If the logic belongs to one aggregate, keep it near that model.
- If the logic is shared across several models, extract a true concern.
- If the logic is a first-class subsystem with params, persistence, summaries, or multiple backends, create a namespaced model-area subsystem.
- If the logic coordinates multiple aggregates or external IO, use a focused service.
- If the logic is presentation-only, keep it in helpers, templates, or explicit edge serializers.
