# Store Manager V2

Rails app with Slim views, Tailwind CSS, Turbo responses, RSpec, and Shopify sync.

## Repo-specific notes

- `Current` is intentionally small in [app/models/current.rb](/Users/geny/Developer/store_manager_v2/app/models/current.rb): it stores `session` and delegates `user`. Do not assume a broader request context.
- Follow the existing Slim + Turbo patterns in [app/views](/Users/geny/Developer/store_manager_v2/app/views).
- Do not add presenters by default. If view code is mostly Ruby and very little markup, first decide whether it is screen-only logic that belongs in a helper or edge template, or a durable domain representation that should stay near the model in `app/models/<model>/...`.
- In this repo, presentation preparation is usually a helper or partial concern, not a presenter layer. If a template starts building small screen-only view structures, move that setup to a helper before inventing a presenter object.
- In this repo, Stimulus controllers should stay small and literal. Let the server render initial structure and prepared view data; let Stimulus own only interaction state, DOM toggles, and loading transitions for one widget.
- For UI and Stimulus work, browser-level feature specs are part of the implementation, not a polish step. The agent cannot truly see what the user sees, so tests are the main way to lock in visible behavior such as loading skeletons, dialog open or close flows, and geometry stability.
- Tailwind styles are centralized under [app/assets/tailwind/application.css](/Users/geny/Developer/store_manager_v2/app/assets/tailwind/application.css) and related files. Prefer extending those over long inline utility strings.
- RSpec already mixes fixtures and `FactoryBot` in [spec/rails_helper.rb](/Users/geny/Developer/store_manager_v2/spec/rails_helper.rb). Reuse the nearest pattern and avoid churn in spec helpers.
- Route Shopify Admin GraphQL work through [app/services/shopify/api/client.rb](/Users/geny/Developer/store_manager_v2/app/services/shopify/api/client.rb) and the query/mutation objects under [app/services/shopify/graphql](/Users/geny/Developer/store_manager_v2/app/services/shopify/graphql).
- Use `mise exec --` for Ruby, Bundler, and RSpec commands in this repo so the active runtime always comes from `mise` instead of the ambient shell PATH.


## Refactor Rules

- Treat the current legacy placement as input data for refactoring, not as the target architecture.
- If logic belongs to one aggregate, first ask which file under `app/models/<model>/` it should live in.
- Prefer capability modules such as `app/models/product/titling.rb`, `app/models/product/editions.rb`, `app/models/sale/statuses.rb`, and `app/models/sale/linking.rb`.
- Prefer model-area workflow objects such as `app/models/product/upsert.rb` or `app/models/sale/creation.rb` over generic `app/services` classes when the workflow is aggregate-local.
- Prefer direct, intention-revealing model APIs before adding a generic service layer between controllers or jobs and the domain.
- Keep controllers focused on request loading, params, and response format; move aggregate-local transactions out of controllers.
- Small params normalization can stay in controllers. When one form grows several normalization helpers or needs failed-submit rebuilding, prefer narrow form-boundary objects such as `app/models/product/form_payload.rb` or `app/models/product/form_rehydrator.rb` over a generic form service.
- Do not default to nested attributes when child records have their own lifecycle. In this repo, the preferred baseline is a small child-resource request surface with its own endpoint and focused form or button.
- Keep composite parent-plus-children forms as an explicit exception. Use them only when the screen is truly one atomic submit and separate child endpoints would make the flow worse.
- In controllers, concerns are for shared request behavior. Shared can mean cross-app or shared by a namespaced controller family; it does not mean “any chunk I want to move out of one controller file”.
- When a side-effect action becomes its own concept, prefer a small nested resource controller over adding another member or collection action to a broad controller.
- Prefer real write routes for command-style actions. A pull, move, link, or confirmation flow should usually become a `POST`, `PATCH`, or `DELETE` resource endpoint, not a `GET`.
- Collection-level workflows can also become small resource controllers. Do not reserve this pattern only for member actions.
- Inline Turbo edit flows can also be resourceful. Prefer a small singular nested controller over `edit_*`, `cancel_*`, and `update_*` actions on the parent controller.
- Keep jobs thin and move aggregate-local workflow to model-area collaborators.
- If a method is reused across parsers, jobs, imports, sync flows, and some views, treat it as a domain representation and keep it near the model rather than moving it to helpers.
- If a method exists only for one screen, dropdown, widget, or response format, move it to helpers, partials, Jbuilder, or Turbo templates.
- If a partial starts building small collections of screen-only view data, prefer a helper method over adding presenters. Use presenters only if the repo explicitly adopts that pattern, which it currently does not.
- If one widget owns one DOM node's loading or selection lifecycle, prefer one focused Stimulus controller to own that node end-to-end instead of splitting responsibility across multiple controllers.
- Prefer obvious JavaScript method names over abstract mini-framework patterns. Optimize for code that reads clearly in one pass.
- When a UI change is risky because it is visual or interaction-heavy, add or update a browser-driven feature spec that exercises the real page. Do not rely only on reading the code and assuming the UI is correct.
- Stable cross-process title builders should usually become instance-oriented methods in a capability such as `app/models/product/titling.rb`, not class methods that take a `product` argument.
- Prefer business verbs such as `publish`, `move_to`, `link_purchase_items`, or `sync_store_references` over controller-shaped or form-shaped names such as `process_form` or `handle_update`.
- When proposing a refactor, name explicit target files rather than saying only “extract a service” or “move logic”.

## Placement Guide

- one aggregate owns the rule: `app/models/<model>/<capability>.rb`
- one aggregate owns a larger workflow: `app/models/<model>/<workflow>.rb`
- one aggregate owns a complex form boundary: `app/models/<model>/form_payload.rb`
- one aggregate needs failed-submit form rebuilding: `app/models/<model>/form_rehydrator.rb`
- shared cross-model behavior: `app/models/concerns/<concern>.rb`
- repeated business query or preload shape: named scope on the owning model
- parser, importer, or payload tied to one aggregate: `app/models/<model>/<integration>/...`
- API transport or GraphQL client code: `app/services/<integration>/...`
- request setup, params, or response concerns: controller or controller concern
- repeated parent loading across several small controllers: `app/controllers/concerns/<resource>_scoped.rb`
- repeated request helpers shared by one namespaced controller family: controller concern
- collection-level command or Turbo endpoint: small controller under `app/controllers/<resource>/...` plus a collection resource route
- child resource with standalone create, update, or destroy behavior: nested controller plus a small edge form, not a default nested-attributes parent form
- true one-submit parent/children screen: composite form plus narrow form payload and rehydration objects
- async transport, retries, scheduling, or pagination: `app/jobs/...`
- screen-only rendering behavior: helper, partial, Turbo template, or view subtree
- controller or job only needs one domain action: add or call a named model method before inventing a service
- route-consuming helper or shared button: use the real route helper or correct polymorphic path shape with the correct `turbo_method`; do not guess from the old route layout
- one controller alone is too big: prefer private methods, another controller, or domain extraction before creating a single-use controller concern

## Skills
A skill is a set of local instructions to follow that is stored in a `SKILL.md` file. Below is the list of skills that can be used. Each entry includes a name, description, and file path so you can open the source for full instructions when using a specific skill.

### Available skills
- rails-domain-architecture: Design or refactor this Rails app toward a model-centric architecture that keeps domain logic, associations, scopes, callbacks, state transitions, and test ownership close to the owning models. Use when planning Rails file layout, deciding between models, concerns, query objects, and services, organizing scopes, extracting capabilities into `app/models/<model>/`, designing request boundaries, or building reusable testing strategies for rich Rails domains. (file: /Users/geny/Developer/store_manager_v2/.codex/skills/rails-domain-architecture/SKILL.md)
- shopify: Use for Shopify Admin API work in this repo. The important local rule is that GraphQL calls go through the shared client and query or mutation objects, with sync logic kept in jobs and parser or serializer layers. (file: /Users/geny/Developer/store_manager_v2/.codex/skills/shopify/SKILL.md)
- commit: Use when asked to write a git commit for this repo. The repo-specific guidance is the Conventional Commit format, common scopes, and avoiding attribution footers. (file: /Users/geny/Developer/store_manager_v2/.codex/skills/commit/SKILL.md)

### Default entry point
- Start with `rails-domain-architecture` for almost every product change in this repo. It is the default router for new models, controllers, views, jobs, tests, and refactors.
- For new model or domain behavior, first read `references/task-router.md`, then `references/principles.md`.
- For new controller, route, or request flow, first read `references/task-router.md`, then `references/full-stack-architecture.md`.
- For new view, partial tree, form, helper, or Turbo response, first read `references/task-router.md`, then `references/full-stack-architecture.md` and `references/screen-first-view-pattern.md`.
- For new jobs, recurring work, or async orchestration, first read `references/task-router.md`, then `references/jobs-architecture.md`.
- For testing guidance or when moving ownership seams, read `references/testing-architecture.md`.
- Add `shopify` together with `rails-domain-architecture` when the task touches Shopify Admin API, sync jobs, parsers, or GraphQL objects.
- Use `commit` only when the user asks for a commit message or a git commit.

### How to use skills
- Discovery: The list above is the skills available in this repo session. Skill bodies live on disk at the listed paths.
- Trigger rules: If the user names a skill with `$SkillName` or plain text, or if the task clearly matches a skill description above, use that skill for that turn. Multiple mentions mean use them all. Do not carry skills across turns unless re-mentioned.
- Missing or blocked: If a named skill is missing or its path cannot be read, say so briefly and continue with the best fallback.
- Minimal loading: Open the skill `SKILL.md` first and read only enough to follow the workflow. If it references `references/`, load only the files needed for the current task.
- Relative paths: Resolve relative paths mentioned by a skill relative to that skill directory first.
- Reuse local assets: If a skill points to local templates, scripts, or references, prefer those over recreating guidance from scratch.
- Coordination: If multiple skills apply, use the minimal set that covers the task and state the order briefly.
