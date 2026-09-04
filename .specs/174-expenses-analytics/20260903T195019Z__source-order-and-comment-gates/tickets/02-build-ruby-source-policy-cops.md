# 02. Build Ruby source-policy cops

Spec: ../spec.md
Status: done
Blocked by: none

## What to build

Provide tested RuboCop rules that deterministically report Ruby depth-first call-order violations and prose comments, while remaining disabled as global gates until legacy cleanup finishes.

This is horizontal lint infrastructure because no cleanup slice can be verified safely before the parser-backed rules and diagnostics exist.

## Acceptance criteria

- [x] `Project/DepthFirstCallOrder` implements the approved zero-incoming-edge traversal for direct instance and singleton definitions, including `class << self`, structural-group projection, first-encounter sharing, and cycle termination.
- [x] The ordering rule reports a callee-before-caller violation even when both methods are public.
- [x] The ordering rule ignores every dispatch form excluded by the Domain Contract.
- [x] `Project/NoProseComments` rejects prose, inline prose, TODO, and FIXME comments without providing a general suppression escape hatch.
- [x] The comment rule accepts only the approved exact directives, shebang/legal forms, and structurally recognized schema-information blocks.
- [x] Both cops are loaded by repository RuboCop configuration, are directly runnable with `--only`, and remain disabled in ordinary full-tree lint until ticket 11.
- [x] `artifacts/ruby-source-policy-audit.md` records exact offense counts by cleanup scope and representative false-positive review results for models, services, other application Ruby, specs, and configuration.
- [x] No application source is reordered and no legacy prose comment is removed in this ticket.

## TDD cases

- `A calls B then C; B calls D` — custom-cop spec expects `A, B, D, C`; write the failing test before traversal logic.
- `callee is public and declared before its caller` — custom-cop spec expects an offense; write the failing test before root selection.
- `shared, disconnected, and cyclic methods` — custom-cop specs prove deterministic first encounter and termination.
- `visibility and method kind` — custom-cop specs prove structural projection and separate instance/singleton graphs.
- `ignored Ruby dispatch` — custom-cop specs cover other receivers, inheritance, `super`, symbol callbacks, aliases, `send`, and generated definitions.
- `prose versus approved directive` — custom-cop specs reject prose/lookalikes and accept each exact approved comment form.
- `process integration` — a fixture run proves each loaded cop returns a normal RuboCop offense and nonzero status.

## Anchors

- `.rubocop.yml:1-28` — custom-cop loading and repository file scope.
- `.rubocop.yml:44-69` — existing structural ordering that takes precedence.
- `app/models/product.rb:93-102` — simple class/private-method case that must pass ordering.
- `app/models/sale.rb:91-118` — public callee-before-caller cases that must fail the new ordering rule.
- `../spec.md:63-75` — complete approved Ruby source-policy contract.

## Coordination notes

- Tickets 04–08 depend on these exact rule names and consume the audit artifact. Do not enable the cops globally or edit their cleanup scopes here.

## Non-goals

- Do not autocorrect, reorder production methods, remove production comments, add parser dependencies, or analyze runtime dispatch.

## Focused verification

- `mise exec -- bin/rspec spec/lib/rubocop/cop/project/depth_first_call_order_spec.rb spec/lib/rubocop/cop/project/no_prose_comments_spec.rb` — proves both Ruby rule contracts.
- `RUBOCOP_CACHE_ROOT=tmp/rubocop_cache mise exec -- bundle exec rubocop --only Project/DepthFirstCallOrder,Project/NoProseComments app spec config` — produces the expected nonzero pre-cleanup audit whose results are recorded in the artifact.
