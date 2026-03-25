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
- one aggregate has a complex form boundary -> `app/models/<model>/form_payload.rb`
- failed form submit needs state rebuilding -> `app/models/<model>/form_rehydrator.rb`
- one screen owns it -> helper, partial, Jbuilder, or Turbo template
- repeated request mechanics -> controller concern or base controller
- repeated request mechanics for one controller family -> controller concern
- multi-aggregate or external orchestration -> focused object under an explicit `app/models/<namespace>/` home
- the controller or job only needs to trigger one domain action -> add or call a named model method
- a custom member or collection action starts to multiply -> consider a nested singular resource controller before adding another action to the parent controller
- a collection-wide command such as move, bulk pull, or lookup endpoint starts growing -> consider a collection resource controller instead of another collection action on the parent
- several nested controllers share one parent lookup -> add a `<resource>_scoped` controller concern
- a single controller feels too large but the logic is not shared -> do not reach for a concern first; prefer another controller or private methods
- a controller grows several `normalized_*` helpers or submit-failure rebuilding for one aggregate form -> extract narrow form objects before inventing a generic service
- an inline Turbo widget has edit/show/update behavior -> prefer a nested singular resource instead of `edit_*`, `cancel_*`, and `update_*` member actions
- a helper or shared button triggers the extracted endpoint -> verify the helper uses the new route helper or correct polymorphic shape and the correct HTTP verb
