# 05. Clean Ruby services

Spec: ../spec.md
Status: done
Blocked by: 02

## What to build

Make every RuboCop-included Ruby service satisfy depth-first call order and the no-prose-comment policy without changing external protocols, request construction, parsing, errors, or public APIs.

## Acceptance criteria

- [x] `app/services` has no `Project/DepthFirstCallOrder` or `Project/NoProseComments` offenses.
- [x] Shopify, SEAL, Woo, and other integration clients retain their method signatures, request behavior, error behavior, and response parsing.
- [x] YARD-style and narrative method comments are removed without replacing them with new prose or changing executable code.
- [x] Method moves preserve class/instance separation, visibility, and protocol behavior.

Test-first does not apply because this is an approved behavior-neutral cleanup. Run the existing service specs after each integration family is reordered; comment-only deletion requires lint and diff inspection.

## Anchors

- `app/services/shopify/api/client.rb:1-145` — representative service with concentrated YARD prose and local helper calls.
- `app/services/seal/api/client.rb:1-120` — second external-client family covered by the same source policy.
- `../artifacts/ruby-source-policy-audit.md` — exact service offenses produced by ticket 02.

## Coordination notes

- Safe to run in parallel with tickets 04 and 06–08 because this ticket owns only `app/services`.

## Non-goals

- Do not change HTTP behavior, credentials, GraphQL/query payloads, retries, parsing, error contracts, tests, or files outside `app/services`.

## Focused verification

- `RUBOCOP_CACHE_ROOT=tmp/rubocop_cache mise exec -- bundle exec rubocop --only Project/DepthFirstCallOrder,Project/NoProseComments app/services` — proves service source policy is clean.
- `mise exec -- bin/rspec spec/services` — catches service-contract changes caused by declaration movement.
- `git diff --check -- app/services` — catches malformed cleanup edits.
