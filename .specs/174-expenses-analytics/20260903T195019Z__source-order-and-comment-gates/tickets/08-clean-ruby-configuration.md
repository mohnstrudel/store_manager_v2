# 08. Clean Ruby configuration

Spec: ../spec.md
Status: done
Blocked by: 02

## What to build

Make RuboCop-included Ruby configuration satisfy depth-first method order and the no-prose-comment policy while preserving every active environment, initializer, boot, and server setting.

## Acceptance criteria

- [x] RuboCop-included Ruby under `config` has no source-policy offenses.
- [x] Template prose and commented-out examples are removed without enabling, disabling, or changing active configuration.
- [x] FriendlyId defaults retain `config.use :reserved`, the existing reserved-word list, and all other active settings.
- [x] Environment, Puma, initializer, and routing behavior remain unchanged.

Test-first does not apply because this is an approved behavior-neutral configuration cleanup. Boot validation plus focused configuration specs are the verification seam.

## Anchors

- `config/initializers/friendly_id.rb:1-109` — concentrated template prose surrounding active FriendlyId settings.
- `config/environments/production.rb:1-112` — representative environment configuration with template comments.
- `config/puma.rb:1-60` — representative server configuration with template comments.
- `../artifacts/ruby-source-policy-audit.md` — exact configuration offenses produced by ticket 02.

## Coordination notes

- Safe to run in parallel with tickets 04–07 because this ticket owns only RuboCop-included Ruby under `config`.

## Non-goals

- Do not change YAML, credentials, secrets, routes, active settings, environment behavior, or files outside Ruby configuration.

## Focused verification

- `RUBOCOP_CACHE_ROOT=tmp/rubocop_cache mise exec -- bundle exec rubocop --only Project/DepthFirstCallOrder,Project/NoProseComments config` — proves Ruby configuration source is clean.
- `mise exec -- bin/rails runner 'exit 0'` — proves the Rails environment boots after cleanup.
- `mise exec -- bin/rspec spec/config` — proves existing configuration contracts remain green.
- `git diff --check -- config` — catches malformed cleanup edits.
