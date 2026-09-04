# 07. Clean Ruby specs

Spec: ../spec.md
Status: done
Blocked by: 02

## What to build

Make all RuboCop-included Ruby specs and support files satisfy depth-first helper order and the no-prose-comment policy while preserving test behavior and coverage.

## Acceptance criteria

- [x] `spec` has no `Project/DepthFirstCallOrder` or `Project/NoProseComments` offenses.
- [x] Generated RSpec instructional prose and commented-out examples are removed rather than converted into replacement comments.
- [x] Shared helpers, mocks, VCR configuration, support contracts, and test setup retain their executable behavior.
- [x] Existing examples, expectations, metadata, and fixture/cassette contents are not weakened or removed as a shortcut.
- [x] Newly added custom-cop specs from ticket 02 remain clean and continue to prove their contracts.

Test-first does not apply because this is an approved behavior-neutral cleanup of test source. The complete RSpec run is the verification seam because the ticket spans shared spec infrastructure and many test families.

## Anchors

- `spec/spec_helper.rb:1-101` — generated prose, commented configuration, and active global RSpec behavior.
- `spec/rails_helper.rb:1-74` — shared Rails test setup with legacy prose comments.
- `spec/support/vcr.rb:1-21` — shared external-HTTP test boundary whose executable behavior must remain intact.
- `../artifacts/ruby-source-policy-audit.md` — exact spec offenses produced by ticket 02.

## Coordination notes

- Run after ticket 02 is merged so its new cop specs are included. It can otherwise proceed in parallel with tickets 04–06 and 08.

## Non-goals

- Do not change application source, test expectations, test coverage, factories, fixtures, cassettes, or test infrastructure behavior.

## Focused verification

- `RUBOCOP_CACHE_ROOT=tmp/rubocop_cache mise exec -- bundle exec rubocop --only Project/DepthFirstCallOrder,Project/NoProseComments spec` — proves Ruby test source is clean.
- `mise exec -- bin/rspec --format progress --color` — proves shared test infrastructure and the complete backend suite still behave identically.
- `git diff --check -- spec` — catches malformed cleanup edits.
