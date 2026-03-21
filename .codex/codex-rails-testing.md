# Codex Rails Testing Guide

Use this document as a reusable testing brief for Codex on other Rails projects. It is based on a Rails app whose tests closely mirror domain ownership, request boundaries, and server-rendered behavior.

## AGENTS.md Snippet

```md
# Rails Testing

Design tests around domain ownership and request boundaries, not around arbitrary layer slogans.

- Mirror the architecture in the test suite. Give model capabilities, query subsystems, controller concerns, jobs, and edge rendering their own focused tests.
- Prefer testing public behavior over private implementation. Assert scopes, commands, side effects, events, fan-out, and rendered responses.
- Keep model capability tests close to the owning concept. If a model is split into capability modules, give those capabilities focused test files too.
- Use `ActionDispatch::IntegrationTest` for controllers so routing, auth, tenancy, params, and rendering are exercised together.
- Test HTML, JSON, and Turbo Stream responses as first-class contracts when the app supports them.
- Use `assert_select` for HTML, `parsed_body` for JSON, and Turbo assertions for stream updates and broadcasts.
- Use system tests sparingly for the highest-risk end-to-end flows such as signup, auth, uploads, drag-and-drop, or navigation handoffs.
- Keep jobs thin and test them semantically: outcome, queue choice, idempotency, retry/discard behavior, checkpointing, and concurrency-sensitive behavior when relevant.
- If domain behavior depends on request context, set `Current` explicitly in tests and treat that context as part of the contract.
- Test lifecycle gates explicitly. States such as draft, cancelled, inactive, or inaccessible may intentionally suppress mentions, notifications, search indexing, or delivery.
- Treat access loss as a domain event worth testing. Verify cleanup of derived user data such as watches, pins, mentions, notifications, or cached visibility artifacts.
- Treat time as a first-class input. Use `freeze_time`, `travel_to`, and `travel` for inactivity windows, bundle periods, due logic, expirations, and cache validators.
- Prefer real records, fixtures, and relations inside the app boundary. Stub only true external edges such as HTTP, web push, SMTP, or third-party SDKs.
- Build small test helpers for repeated architectural friction such as sign-in, tenant path setup, HTML normalization, search index setup, caching toggles, and VCR management.
- Use fixtures as reusable domain scenarios, not as a dumping ground. Keep them deterministic enough that ordering, tenancy, and timestamps remain trustworthy.
- When enqueueing matters, use `perform_enqueued_jobs` narrowly so tests reveal which async boundaries are part of the behavior.
- Avoid asserting on private callbacks or exact internal query shape unless the query itself is the public contract.
```

## What to Learn From This Style

- The test suite mirrors model ownership. A capability module can be a real public API, so it deserves its own tests.
- Controller tests are mostly request tests, not isolated controller-unit tests.
- Edge rendering is part of the contract, so HTML, JSON, and Turbo Stream outputs are asserted directly.
- Time, tenancy, `Current`, and async delivery are treated as architectural inputs, not incidental setup.
- The suite prefers real persistence inside the application boundary and stubs only external systems.

## Layer Rules

## Model Tests

- Test scopes, predicates, commands, validations, and side effects together when they describe one business concept.
- Set `Current.session`, `Current.user`, or `Current.account` when the capability depends on request context.
- Assert domain outcomes such as events, notifications, mentions, bundle creation, cleanup, or timestamps.
- Cover negative behavior too, especially lifecycle gates like drafts suppressing downstream fan-out.
- Use `assert_difference`, `assert_changes`, `assert_no_difference`, and `assert_no_changes` to keep intent clear.

## Controller and Request Tests

- Prefer `ActionDispatch::IntegrationTest` over narrow controller isolation.
- Exercise real routes, authentication flow, tenant prefixes, and authorization-scoped relations.
- Assert the response contract in every supported format.
- Test forbidden and not-found paths when access changes.
- Use controller concern tests for request mechanics such as timezone, platform, ETag variation, and forgery handling.

## View, Helper, and Turbo Tests

- Use helper tests for presentation-specific logic and sanitization.
- Use `assert_select` for meaningful HTML fragments rather than broad body-string matches when possible.
- Use Turbo assertions for replacements, removals, inserts, and broadcasts.
- Keep most rendering coverage below the system-test layer.

## Job and Mailer Tests

- Test jobs for the behavior they trigger, not just that `perform` calls a method.
- Assert queue choice, idempotency, resumability, and discard/retry behavior when those are part of the contract.
- Use focused transport tests for SMTP, push, webhook delivery, or other external boundaries.
- If a model owns `*_later` methods, test the domain behavior at that seam rather than inventing a separate service seam.

## Fixtures, Helpers, and Setup

- Use fixtures to encode realistic domain scenarios and access relationships.
- Make identifiers and ordering deterministic when the app depends on ordered UUIDs or time-sensitive creation semantics.
- Centralize repeated setup in helpers for:
- login and session setup
- tenant path or `script_name` handling
- search-index reset/setup
- caching toggles
- HTML comparison
- VCR cassette naming
- browser or WebAuthn helpers

## Anti-Default LLM Checklist

- Do not replace rich model capability tests with generic service tests if the service is not the true owner.
- Do not test controller internals when a real request test expresses the contract better.
- Do not stub Active Record relations or callbacks so heavily that domain behavior disappears.
- Do not ignore time, tenancy, access loss, or `Current` state in tests for context-sensitive features.
- Do not push all rendering checks into brittle system tests when helper, integration, or Turbo tests are more direct.
- Do not skip negative-path tests for drafts, inactive users, cancelled accounts, or inaccessible records; those states often define the real architecture.
