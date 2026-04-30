# Rails Task Router

Use this file first. It maps a task to the smallest useful reference set.

## Defaults For This Repo

- Start with `rails-domain-architecture` for almost every app change.
- Add `shopify` only when the task touches Shopify GraphQL, sync jobs, parsers, importers, or payloads.
- Keep `Current` small.
- Do not add presenters by default.
- Prefer explicit target files under `app/models/<model>/...`.
- Prefer direct model APIs over inserting a generic service layer between the request edge and the domain.

## Which Reference To Read

- model or domain behavior -> `principles.md`
- controller, route, helper, Turbo, or presentation placement -> `full-stack-architecture.md`
- view tree or partial organization -> `screen-first-view-pattern.md`
- job, scheduler, import, sync flow -> `jobs-architecture.md`
- tests or seam placement -> `testing-architecture.md`

## Common Decisions

- one aggregate owns it -> `app/models/<model>/<capability>.rb`
- one aggregate owns a workflow -> `app/models/<model>/<workflow>.rb`
- one aggregate has a complex form boundary -> `app/models/<model>/form_payload.rb` and maybe `form_rehydrator.rb`
- one screen owns it -> helper, partial, Jbuilder, or Turbo template
- repeated request mechanics -> base controller or controller concern, including one namespaced controller family
- multi-aggregate or external orchestration -> focused object under an explicit `app/models/<namespace>/` home
- the controller or job only needs to trigger one domain action -> add or call a named model method
- custom member, collection, or inline Turbo actions start to multiply -> consider a nested or collection resource controller
- one controller feels too large but the logic is not shared -> prefer another controller, private methods, or model extraction before a concern
- a controller grows several `normalized_*` helpers or submit-failure rebuilding -> extract narrow form objects before inventing a generic service
- a helper or shared button triggers the extracted endpoint -> verify the helper uses the new route helper or correct polymorphic shape and the correct HTTP verb
