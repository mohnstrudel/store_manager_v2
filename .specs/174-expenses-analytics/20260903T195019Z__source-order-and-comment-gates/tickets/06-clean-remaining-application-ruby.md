# 06. Clean remaining application Ruby

Spec: ../spec.md
Status: done
Blocked by: 02

## What to build

Make RuboCop-included controllers, jobs, mailers, policies, and helpers satisfy depth-first call order and the no-prose-comment policy without changing request, scheduling, delivery, authorization, view-helper, or error behavior.

## Acceptance criteria

- [x] `app/controllers`, `app/jobs`, `app/mailers`, `app/policies`, and `app/helpers` have no source-policy offenses.
- [x] ApplicationJob retains its retry configuration and existing disabled `discard_on` behavior while prose comments are removed.
- [x] Controller actions, job callbacks/retries, mail delivery, and policy decisions remain unchanged.
- [x] Method moves preserve visibility, callback/macro registration, and existing structural groups.

Test-first does not apply because this is an approved behavior-neutral cleanup. Run the matching existing specs for files whose methods move; comment-only deletion requires lint and diff inspection.

## Anchors

- `app/jobs/application_job.rb:1-11` — representative prose comments around executable and disabled job configuration.
- `app/controllers/application_controller.rb:1-38` — controller boundary representative for ordering cleanup.
- `../artifacts/ruby-source-policy-audit.md` — exact non-model/non-service application offenses produced by ticket 02.

## Coordination notes

- Safe to run in parallel with tickets 04, 05, 07, and 08 because file ownership does not overlap.

## Non-goals

- Do not enable disabled behavior, change routes or authorization, alter job timing/retries, change mail output, edit models/services/specs/configuration, or add comments.

## Focused verification

- `RUBOCOP_CACHE_ROOT=tmp/rubocop_cache mise exec -- bundle exec rubocop --only Project/DepthFirstCallOrder,Project/NoProseComments app/controllers app/jobs app/mailers app/policies app/helpers` — proves the owned application paths are clean.
- `mise exec -- bin/rspec spec/controllers spec/jobs spec/mailers spec/policies spec/helpers` — catches behavior changes in the owned Rails boundaries.
- `git diff --check -- app/controllers app/jobs app/mailers app/policies app/helpers` — catches malformed cleanup edits.
