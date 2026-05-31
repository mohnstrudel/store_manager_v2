# Rails Task Router

Use this file first. It maps a task to the smallest useful reference set.

## Defaults For This Repo

- Start with `rails-domain-architecture` for backend and domain work.
- Start with `frontend-architecture` for React pages, shared components, hooks, and browser-side interaction work.
- Add `shopify` only when the task touches Shopify GraphQL, sync jobs, parsers, importers, or payloads.
- Keep `Current` small.
- Do not add presenters by default.
- Prefer explicit target files under `app/models/<model>/...`.
- Prefer direct model APIs over inserting a generic service layer between the request edge and the domain.

## Which Reference To Read

- model or domain behavior -> `principles.md`
- controller, route, backend helper, or backend presentation placement -> `full-stack-architecture.md`
- backend view tree or partial organization -> `screen-first-view-pattern.md`
- React page, shared component, hook, or browser-side widget -> `frontend-architecture`
- frontend component testing or browser-level UI coverage -> `codex-frontend-testing.md`
- job, scheduler, import, sync flow -> `jobs-architecture.md`
- backend tests or seam placement -> `testing-architecture.md`

## Common Decisions

- one aggregate owns it -> `app/models/<model>/<capability>.rb`
- one aggregate owns a workflow -> `app/models/<model>/<workflow>.rb`
- one aggregate has a complex form boundary -> `app/models/<model>/form_payload.rb` and maybe `form_rehydrator.rb`
- one backend screen owns it -> helper, partial, Jbuilder, or response template
- repeated request mechanics -> base controller or controller concern, including one namespaced controller family
- multi-aggregate or external orchestration -> focused object under an explicit `app/models/<namespace>/` home
- the controller or job only needs to trigger one domain action -> add or call a named model method
- custom member, collection, or inline actions start to multiply -> consider a nested or collection resource controller
- one controller feels too large but the logic is not shared -> prefer another controller, private methods, or model extraction before a concern
- a controller grows several `normalized_*` helpers or submit-failure rebuilding -> extract narrow form objects before inventing a generic service
- a helper or shared button triggers the extracted endpoint -> verify the helper uses the new route helper or correct polymorphic shape and the correct HTTP verb
