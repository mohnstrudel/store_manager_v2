# 04. Clean Ruby models

Spec: ../spec.md
Status: done
Blocked by: 02

## What to build

Make every RuboCop-included Ruby model satisfy depth-first call order and the no-prose-comment policy without changing model behavior, visibility, callbacks, persistence, or public APIs.

## Acceptance criteria

- [x] `app/models` has no `Project/DepthFirstCallOrder` or `Project/NoProseComments` offenses.
- [x] `Product` retains its existing method behavior, callback registration, and generated schema block while removing the prose explanation above the Seal placeholder constant.
- [x] `Sale#follow_up_payment?` precedes `payment_plans_for_display`, and `reconcile_installment_attribution!` precedes `installment_payment_items`.
- [x] `Sale` retains its existing public API and behavior while removing the prose explanation above `installment_payment_items`.
- [x] Included model capabilities are repaired only in their own files; no cross-file call graph is invented.
- [x] Method moves preserve visibility and existing RuboCop structural groups.

Test-first does not apply because this is an approved behavior-neutral cleanup. Run affected model specs after each group of method moves; comment-only deletion requires lint and diff inspection.

## Anchors

- `app/models/product.rb:21-102` — Product structure, Seal comment, class method, and callback method.
- `app/models/sale.rb:48-118` — Sale structure, two ordering violations, and installment prose comment.
- `app/models/sale/profitability.rb:1-97` — representative model capability with concentrated prose-comment debt.
- `../artifacts/ruby-source-policy-audit.md` — exact model offenses produced by ticket 02.

## Coordination notes

- Safe to run in parallel with tickets 05–08 because this ticket owns only `app/models`.

## Non-goals

- Do not change model semantics, association/macro order, callback registration, generated schema comments, tests, or files outside `app/models`.

## Focused verification

- `RUBOCOP_CACHE_ROOT=tmp/rubocop_cache mise exec -- bundle exec rubocop --only Project/DepthFirstCallOrder,Project/NoProseComments app/models` — proves the model source policy is clean.
- `mise exec -- bin/rspec spec/models` — catches behavior changes caused by model declaration movement.
- `git diff --check -- app/models` — catches malformed cleanup edits.
