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
- request or controller behavior -> `spec/requests/...`
- job transport behavior -> `spec/jobs/...`
- helper-only presentation logic -> `spec/helpers/...`
- only the highest-risk end-to-end flows -> `spec/features/...`

## What Codex Often Gets Wrong

- Do not default to service specs when the behavior belongs to a model capability.
- Do not keep old service or form specs around after ownership moved into the model layer.
- Do not replace request tests with narrow controller stubs.
- Do not leave tests at an old seam after ownership moved.
- Do not skip negative-path rules where state suppresses side effects.
- Do not hide time-based rules in scheduler tests when they really belong to the domain.

## Repo-Specific Bias

- When a feature depends on `Current`, set that context explicitly in tests.
- Keep edge-format coverage close to the response contract for Turbo and server-rendered flows.
- Prefer stable domain scenarios over clever helper-heavy setup.
