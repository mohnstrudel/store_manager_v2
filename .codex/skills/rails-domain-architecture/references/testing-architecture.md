# Rails Testing Architecture

Use this file for the non-obvious test placement and seam rules in this repo.
Frontend component and browser-level UI testing live in `codex-frontend-testing.md`.

## Core Rules

- Tests should follow ownership.
- Prefer the public seam of a concept over private internals.
- Keep real application behavior inside the app boundary and stub only true external systems.
- Treat `Current`, time, async delivery, and access boundaries as architectural inputs.
- Prefer testing named domain commands and capability APIs over reproducing controller or form choreography in every example.

## Default Test Seams

- model capability -> `spec/models/<model>/<capability>_spec.rb`
- form payload or rehydration object -> `spec/models/<model>/form_payload_spec.rb` or `spec/models/<model>/form_rehydrator_spec.rb`
- request or controller behavior -> `spec/requests/...`
- job transport behavior -> `spec/jobs/...`
- helper-only presentation logic -> `spec/helpers/...`
- only the highest-risk end-to-end flows -> `spec/features/...`

## What Codex Often Gets Wrong

- Do not keep specs at an old service, form, or controller seam after ownership moves into the model layer.
- Do not replace request behavior with narrow controller stubs when the route or rendered trigger is the real contract.
- Do not keep controller-only normalization specs once that logic moves into a form payload object; test the object and keep one wiring check.
- Do not skip negative-path rules where state suppresses side effects, or hide domain time rules in scheduler tests.
- Do not stop at code inspection for browser-side changes when rendered DOM behavior is the risk.

## Repo-Specific Bias

- When a feature depends on `Current`, set that context explicitly in tests.
- Keep edge-format coverage close to the response contract for backend-rendered flows.
- Prefer stable domain scenarios over clever helper-heavy setup.
- When a feature stubs record behavior for a rendered page, make sure the controller actually uses that same record instance or stub at the seam the controller loads.
- For frontend UI interactions, a good feature spec often checks one or more of: open or closed state, loading classes, geometry stability, source changes, and whether a user-visible action can be repeated after state changes.
