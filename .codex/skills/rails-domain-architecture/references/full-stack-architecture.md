# Rails Full-Stack Architecture

Use this file for the non-obvious request, controller, and presentation rules in this repo.

## Request Boundary

- Start from the real access boundary, not `Model.all`.
- Keep `Current` small. In this repo it stores `session` and delegates `user`.
- Rehydrate any request-dependent context explicitly in jobs or other async code when needed.

## Controllers

- Controllers are request adapters, not domain homes.
- Keep in controllers:
  - boundary loading
  - params normalization
  - format choice
  - render or redirect
- Move out of controllers:
  - long relation chains
  - aggregate-local transactions
  - business-state branching
  - recipient or payload logic
  - hand-built HTML or JSON

## Placement Decisions

- repeated request mechanics -> base controllers or controller concerns
- aggregate-owned behavior -> `app/models/<model>/<capability>.rb`
- aggregate-local orchestration -> `app/models/<model>/<workflow>.rb`
- presentation-only branching -> helpers, partials, Jbuilder, Turbo templates

## Presentation Boundary

- Keep screen-specific logic at the edge.
- Do not add presenters by default.
- Use this sorting rule:
  - one screen or one response format -> helper, partial, Jbuilder, Turbo template
  - reused across jobs, exports, notifications, or integrations -> model-area representation object
  - business identity or state text -> model or capability module

## What Codex Often Gets Wrong

- Do not keep screen-specific text on the model just because it is reused across templates.
- Do not move true domain payload builders into helpers.
- Do not keep adding root-level partials after a screen subtree already exists.
- Do not let deep partials reach into `params` or associations when explicit state can be passed once.

## View Defaults

- Follow the existing Slim plus Turbo patterns in this repo.
- Keep Turbo Stream templates at the resource root when they are endpoint-owned.
- Prefer explicit nested render paths once a subtree exists.
