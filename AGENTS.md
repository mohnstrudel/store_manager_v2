# Store Manager V2

Rails app with Slim views, Tailwind CSS, Turbo responses, RSpec, and Shopify sync.

## Repo-specific notes

- `Current` is intentionally small in [app/models/current.rb](/Users/geny/Developer/store_manager_v2/app/models/current.rb): it stores `session` and delegates `user`. Do not assume a broader request context.
- Follow the existing Slim + Turbo patterns in [app/views](/Users/geny/Developer/store_manager_v2/app/views).
- Do not add presenters by default. If view code is mostly Ruby and very little markup, first decide whether it is screen-only logic that belongs in a helper or edge template, or a durable domain representation that should stay near the model in `app/models/<model>/...`.
- Tailwind styles are centralized under [app/assets/tailwind/application.css](/Users/geny/Developer/store_manager_v2/app/assets/tailwind/application.css) and related files. Prefer extending those over long inline utility strings.
- RSpec already mixes fixtures and `FactoryBot` in [spec/rails_helper.rb](/Users/geny/Developer/store_manager_v2/spec/rails_helper.rb). Reuse the nearest pattern and avoid churn in spec helpers.
- Route Shopify Admin GraphQL work through [app/services/shopify/api/client.rb](/Users/geny/Developer/store_manager_v2/app/services/shopify/api/client.rb) and the query/mutation objects under [app/services/shopify/graphql](/Users/geny/Developer/store_manager_v2/app/services/shopify/graphql).


## Refactor Rules

- Treat the current legacy placement as input data for refactoring, not as the target architecture.
- If logic belongs to one aggregate, first ask which file under `app/models/<model>/` it should live in.
- Prefer capability modules such as `app/models/product/titling.rb`, `app/models/product/editions.rb`, `app/models/sale/statuses.rb`, and `app/models/sale/linking.rb`.
- Prefer model-area workflow objects such as `app/models/product/upsert.rb` or `app/models/sale/creation.rb` over generic `app/services` classes when the workflow is aggregate-local.
- Keep controllers focused on request loading, params, and response format; move aggregate-local transactions out of controllers.
- Keep jobs thin and move aggregate-local workflow to model-area collaborators.
- If a method is reused across parsers, jobs, imports, sync flows, and some views, treat it as a domain representation and keep it near the model rather than moving it to helpers.
- If a method exists only for one screen, dropdown, widget, or response format, move it to helpers, partials, Jbuilder, or Turbo templates.
- Stable cross-process title builders should usually become instance-oriented methods in a capability such as `app/models/product/titling.rb`, not class methods that take a `product` argument.
- When proposing a refactor, name explicit target files rather than saying only “extract a service” or “move logic”.

## Skills
A skill is a set of local instructions to follow that is stored in a `SKILL.md` file. Below is the list of skills that can be used. Each entry includes a name, description, and file path so you can open the source for full instructions when using a specific skill.

### Available skills
- rails-domain-architecture: Design or refactor this Rails app toward a model-centric architecture that keeps domain logic, associations, scopes, callbacks, state transitions, and test ownership close to the owning models. Use when planning Rails file layout, deciding between models, concerns, query objects, and services, organizing scopes, extracting capabilities into `app/models/<model>/`, designing request boundaries, or building reusable testing strategies for rich Rails domains. (file: /Users/geny/Developer/store_manager_v2/.codex/skills/rails-domain-architecture/SKILL.md)
- shopify: Use for Shopify Admin API work in this repo. The important local rule is that GraphQL calls go through the shared client and query or mutation objects, with sync logic kept in jobs and parser or serializer layers. (file: /Users/geny/Developer/store_manager_v2/.codex/skills/shopify/SKILL.md)
- commit: Use when asked to write a git commit for this repo. The repo-specific guidance is the Conventional Commit format, common scopes, and avoiding attribution footers. (file: /Users/geny/Developer/store_manager_v2/.codex/skills/commit/SKILL.md)

### How to use skills
- Discovery: The list above is the skills available in this repo session. Skill bodies live on disk at the listed paths.
- Trigger rules: If the user names a skill with `$SkillName` or plain text, or if the task clearly matches a skill description above, use that skill for that turn. Multiple mentions mean use them all. Do not carry skills across turns unless re-mentioned.
- Missing or blocked: If a named skill is missing or its path cannot be read, say so briefly and continue with the best fallback.
- Minimal loading: Open the skill `SKILL.md` first and read only enough to follow the workflow. If it references `references/`, load only the files needed for the current task.
- Relative paths: Resolve relative paths mentioned by a skill relative to that skill directory first.
- Reuse local assets: If a skill points to local templates, scripts, or references, prefer those over recreating guidance from scratch.
- Coordination: If multiple skills apply, use the minimal set that covers the task and state the order briefly.
