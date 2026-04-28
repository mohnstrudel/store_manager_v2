# Rails Testing Architecture

Use this file for the non-obvious test placement and seam rules in this repo.

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
- browser-driven widget geometry, loading states, or JS interaction contracts -> focused `spec/features/...` coverage before introducing screenshot-diff tooling
- when the UI detail itself is the risky part and the agent cannot directly verify it by sight -> prefer a focused browser-level feature spec over confidence-by-inspection

## What Codex Often Gets Wrong

- Do not keep specs at an old service, form, or controller seam after ownership moves into the model layer.
- Do not replace request behavior with narrow controller stubs when the route or rendered trigger is the real contract.
- Do not keep controller-only normalization specs once that logic moves into a form payload object; test the object and keep one wiring check.
- Do not skip negative-path rules where state suppresses side effects, or hide domain time rules in scheduler tests.
- Do not jump straight to pixel-diff tooling for UI regressions; focused browser specs are usually cheaper and more durable.
- Do not stop at code inspection for JavaScript or CSS-heavy changes when rendered DOM behavior is the risk.

## Repo-Specific Bias

- When a feature depends on `Current`, set that context explicitly in tests.
- Keep edge-format coverage close to the response contract for Turbo and server-rendered flows.
- Prefer stable domain scenarios over clever helper-heavy setup.
- When a feature stubs record behavior for a rendered page, make sure the controller actually uses that same record instance or stub at the seam the controller loads.
- For Stimulus widgets in this repo, a good feature spec often checks one or more of: open or closed state, loading classes, geometry stability, source changes, and whether a user-visible action can be repeated after state changes.
