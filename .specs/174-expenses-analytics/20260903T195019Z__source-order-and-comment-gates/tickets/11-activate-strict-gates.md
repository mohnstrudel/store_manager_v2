# 11. Activate strict repository gates

Spec: ../spec.md
Status: done
Blocked by: 04, 05, 06, 07, 08, 09, 10

## What to build

Turn the clean backend and frontend source policies into unavoidable local and pull-request gates, and give all repository agents the two concise approved instructions.

## Acceptance criteria

- [x] Ruby ordering and no-prose-comment cops are enabled in ordinary RuboCop runs with no baseline, warning-only mode, broad exclusion, or offense fingerprint.
- [x] Frontend ordering, JS/TS/TSX comment, and CSS comment checks run through ordinary `pnpm lint` with the same strict behavior.
- [x] `bin/lint` and `bin/test` continue to run both authoritative stack gates successfully.
- [x] Pull-request CI runs RuboCop and `pnpm lint` and fails when either command fails.
- [x] `AGENTS.md` contains the approved one-line depth-first order rule and the approved no-prose-comment rule, without duplicating algorithms or command details.
- [x] The discretionary code-comment exception is removed, and `CLAUDE.md` remains a symlink to `AGENTS.md`.
- [x] Full-tree RuboCop and frontend lint complete with zero source-policy offenses.
- [x] No application source cleanup or new policy exception is hidden in this activation ticket.

## TDD cases

- `ordinary backend lint sees a deliberate fixture violation` — process integration spec proves global RuboCop activation before configuration is finalized.
- `ordinary frontend lint sees a deliberate fixture violation` — process integration test proves `pnpm lint` activation before scripts are finalized.

## Anchors

- `.rubocop.yml:1-28` — backend global rule activation and scope.
- `.oxlintrc.json:1-26` — frontend plugin activation and generated-path exclusion.
- `package.json:4-16` — authoritative frontend lint command.
- `bin/lint:1-7` — combined local lint gate.
- `bin/test:82-90` — combined repository verification gate.
- `.github/workflows/tests.yml:33-93` — pull-request jobs currently missing lint steps.
- `AGENTS.md:18-46` — existing Completion and discretionary comment policy.
- `CLAUDE.md:1-1` — shared instruction symlink that must remain intact.

## Coordination notes

- This ticket owns shared configuration and runs last. Recheck all prerequisite branches are merged and the two audit artifacts report zero remaining offenses before enabling strict defaults.
- The coordinating task runs the complete backend and frontend suites after this ticket because the completed set moved declarations across cross-cutting source paths.

## Non-goals

- Do not add agent-specific hooks, editor plugins, autocorrection, baselines, new source exclusions, implementation cleanup, or duplicated prompt instructions.

## Focused verification

- `mise exec -- bin/rspec spec/lib/rubocop/cop/project/depth_first_call_order_spec.rb spec/lib/rubocop/cop/project/no_prose_comments_spec.rb` — proves backend rule behavior remains green under global activation.
- `mise exec -- pnpm exec vitest run tools/source-policy/frontend` — proves frontend rule behavior remains green under global activation.
- `bin/lint` — proves the complete strict local lint gate passes.
- `git diff --check -- .rubocop.yml .oxlintrc.json package.json bin/lint bin/test .github/workflows/tests.yml AGENTS.md` — catches malformed shared-gate edits.
