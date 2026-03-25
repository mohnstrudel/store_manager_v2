# Rails Task Router

Use this file first. It maps a task to the smallest useful reference set.

## Defaults For This Repo

- Start with `rails-domain-architecture` for almost every app change.
- Add `shopify` only when the task touches Shopify GraphQL, sync jobs, parsers, importers, or payloads.
- Keep `Current` small.
- Do not add presenters by default.
- Prefer explicit target files under `app/models/<model>/...`.

## Which Reference To Read

- model or domain behavior -> `principles.md`
- controller, route, helper, Turbo, or presentation placement -> `full-stack-architecture.md`
- view tree or partial organization -> `screen-first-view-pattern.md`
- job, scheduler, import, sync flow -> `jobs-architecture.md`
- tests or seam placement -> `testing-architecture.md`

## Common Decisions

- one aggregate owns it -> `app/models/<model>/<capability>.rb`
- one aggregate owns a workflow -> `app/models/<model>/<workflow>.rb`
- one screen owns it -> helper, partial, Jbuilder, or Turbo template
- repeated request mechanics -> controller concern or base controller
- multi-aggregate or external orchestration -> focused service object
