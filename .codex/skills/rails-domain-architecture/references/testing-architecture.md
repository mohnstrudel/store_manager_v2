# Rails Testing Architecture

Use this guide when the task involves Rails tests, test layout, fixture strategy, adding coverage for a refactor, or deciding where a behavior should be tested.

## Core Stance

- Tests should follow ownership.
- Prefer the public seam of a concept over its private internals.
- Keep real application behavior inside the app boundary and stub only external systems.
- Treat tenancy, time, async delivery, and request context as architecture, not as incidental setup.

## 1. Mirror the Architecture in the Suite

- If the model layer is organized into capability modules, let tests mirror that shape.
- Good examples:
- `test/models/card/closeable_test.rb`
- `test/models/card/eventable_test.rb`
- `test/models/card/golden_test.rb`
- `test/models/concerns/mentions_test.rb`

- This keeps test ownership aligned with code ownership.
- It also makes rich models safer to navigate because each capability has an obvious place for coverage.

## 2. Model Tests Should Exercise the Real Capability Seam

- Test:
- scopes
- predicates
- commands
- validations
- side effects
- fan-out outcomes

- Prefer assertions like:
- `assert_difference`
- `assert_changes`
- `assert_no_difference`
- `assert_no_changes`

- When a capability depends on request context, set `Current` explicitly instead of bypassing that dependency.
- Do not test private callbacks directly when the public command already proves the behavior.

## 3. Lifecycle Gates Belong in Tests Too

- Rich Rails domains often encode "nothing should happen" rules.
- Test them explicitly.

Typical examples:
- drafts do not create mentions
- drafts do not appear in search
- inactive users do not receive pushes
- cancelled accounts do not send email
- inaccessible users lose derived visibility data

- These tests teach the architecture where the true state boundaries live.

## 4. Time Is a Domain Input

- Use `freeze_time`, `travel_to`, and `travel` whenever the behavior depends on:
- bundle windows
- inactivity thresholds
- expiration
- rate limiting
- freshness validators
- ordered UUID or timestamp assumptions

- Time-sensitive tests are often the clearest way to see whether a rule belongs in the domain object or in a scheduler concern.
- If a time rule affects a business concept, keep it near the domain and test it there.

## 5. Prefer Integration Tests for Controllers

- Use `ActionDispatch::IntegrationTest` for most controller behavior.
- Exercise:
- routing
- params
- authentication
- tenant prefixes
- authorization
- content negotiation
- rendering

- This works especially well in Rails apps where controllers are thin and the real logic lives in models and relations.
- Request tests are also a better fit for controller concerns such as timezone selection, request forgery behavior, platform detection, or cache validators.

## 6. Test the Edge Contract in the Right Format

- Use `assert_select` for HTML structure and significant UI text.
- Use `response.parsed_body` for JSON APIs.
- Use Turbo assertions for stream replacements, inserts, removals, and broadcasts.
- Keep system tests for a small number of high-risk end-to-end flows.

- In server-rendered Rails apps, response shape is a real contract.
- Do not treat HTML and Turbo behavior as untestable presentation noise.

## 7. Jobs Should Be Tested Semantically

- A thin job still deserves tests when any of these matter:
- queue selection
- idempotency
- retry or discard behavior
- checkpointing
- concurrency-sensitive behavior
- durable async side effects

- Test the job as a transport seam around domain behavior.
- If the job is only a shell, keep the heavy assertions focused on the model or subsystem it calls.
- If the job adds checkpointing or retry semantics, test those semantics explicitly.

## 8. Fixtures Should Encode Domain Scenarios

- Use fixtures as stable domain stories:
- users with different access
- boards with different visibility
- cards in different states
- notifications, watches, mentions, and pins across access boundaries

- Determinism matters.
- If your app relies on ordered UUIDs or timestamp semantics, make fixtures preserve those assumptions so `first`, `last`, and "newer than fixtures" remain trustworthy.

## 9. Build Helpers Around Architectural Friction

- Create small test helpers for repeated setup that would otherwise distract from the behavior under test.

Strong candidates:
- sign-in helpers
- tenant path or `script_name` helpers
- HTML normalization helpers
- search-index reset/setup helpers
- VCR cassette helpers
- caching toggles
- WebAuthn helpers
- command parser helpers

- Good helpers reduce ceremony without hiding the architecture.

## 10. Stub Only True Boundaries

- Prefer real records and real persistence inside the application boundary.
- Stub or record only external edges such as:
- HTTP APIs
- SMTP transport
- web push delivery
- browser-only integration points

- Do not mock away the model layer so thoroughly that the test no longer proves domain behavior.

## 11. What the Tests Teach About the Model Layer

- A lifecycle state can be a domain firewall. Draft, inactive, cancelled, or inaccessible states may intentionally block downstream systems.
- Access loss can be a meaningful domain transition that triggers cleanup of watches, pins, mentions, notifications, and other derived records.
- Time windows belong in domain objects when users experience them as product behavior.
- Public APIs may have both synchronous and asynchronous faces, and both should stay close to the owning concept.
- A well-factored model layer is often easiest to recognize by how easy it is to test one capability at a time.

## 12. Anti-Default LLM Checklist

- Do not default to service-layer tests if the behavior is owned by a model capability.
- Do not replace request tests with narrow controller stubs.
- Do not ignore negative-path behavior where state suppresses side effects.
- Do not let time-dependent rules hide in scheduler code if they are really domain rules.
- Do not solve brittle tests by mocking away the architecture instead of improving the seam.
