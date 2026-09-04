# Source-order and no-comment gates

This iteration supersedes `../20260903T194153Z__depth-first-call-order-gates/spec.md`. It corrects the traversal-root contract found by auditing `Product` and `Sale` and adds the approved no-prose-comment policy.

## Problem

Current backend and frontend linting accepts local methods and functions in declaration orders that do not follow their call sites. The first spec incorrectly treated every public or exported declaration as a traversal root; that would accept `Sale#payment_plans_for_display` above its caller and miss the target violation.

The repository also asks agents to avoid most comments but leaves an exception to model judgment. That exception does not match the approved policy: hand-written source code must contain no prose comments. Existing source has material legacy debt. A preliminary syntax-level audit found about 1,155 candidate Ruby prose-comment lines in 118 files after excluding magic comments and schema blocks, about 204 candidate JavaScript/TypeScript/TSX lines in 29 linted frontend files, and 30 CSS comment lines. These are audit estimates, not expected gate results.

`Product` and `Sale` expose the intended behavior:

- `Product` passes method order: its class method and callback method have no same-owner method calls. The generated schema block remains allowed; the prose explanation above `SEAL_INSTALLMENT_PLACEHOLDER_SHOPIFY_ID` fails the comment rule.
- `Sale` has two method-order violations: `follow_up_payment?` must precede `payment_plans_for_display`, and `reconcile_installment_attribution!` must precede `installment_payment_items`. Its prose explanation above `installment_payment_items` fails the comment rule.

The current vendor guidance still supports a hybrid design: OpenAI recommends lean prompts that state each rule once and retain style guidance for measured gaps; Anthropic recommends short repository instructions and deterministic checks for requirements that must always hold. `CLAUDE.md` links to `AGENTS.md`, so one concise instruction source serves both agent families.

Evidence:

- `.rubocop.yml` and RuboCop 1.88 provide the backend lint extension point.
- `.oxlintrc.json`, Oxlint 1.69, and TypeScript provide the frontend lint extension point. Oxlint JavaScript plugins are alpha, so adapter-independent logic is required.
- `bin/lint` and `bin/test` already run RuboCop and Oxlint.
- `.github/workflows/tests.yml` currently runs tests but not either linter.
- OpenAI model guidance: https://developers.openai.com/api/docs/guides/latest-model
- Anthropic Claude Code best practices: https://code.claude.com/docs/en/best-practices
- Oxlint JavaScript plugins: https://oxc.rs/docs/guide/usage/linter/js-plugins

## Goal and approach

Make source layout deterministic through tested backend and frontend lint rules, remove existing violations, enforce the rules locally and in pull-request CI, and keep only concise policy statements in `AGENTS.md`. The tools, tests, and diagnostics own detailed algorithms and exceptions.

Observable success:

- `A, B, D, C` passes when `A` calls `B` then `C`, and `B` calls `D`; `A, B, C, D` fails.
- A callee declared above its caller fails even when both are public or exported.
- Shared helpers, disconnected declarations, nested functions, and recursive cycles produce deterministic results.
- Prose comments fail in covered Ruby, JavaScript, TypeScript, TSX, and CSS source.
- Exact required directives and generated Ruby schema blocks pass.
- Existing `Product` and `Sale` satisfy both rules after behavior-neutral cleanup.
- Local lint and pull-request CI fail on either policy violation.

## Approved decisions

- **Approved — deterministic authority.** Executable checks, not agent judgment, decide method order and comment validity.
- **Approved — two ordering implementations.** A repository-local RuboCop cop owns Ruby ordering. Adapter-independent frontend ordering logic runs through a thin local Oxlint-compatible plugin.
- **Approved — corrected traversal roots.** Methods or functions with no incoming same-owner call edges are roots. Traverse roots in source order. After roots, traverse any unvisited declarations in source order to cover cycles. Public/exported status does not make an already called declaration an independent root.
- **Approved — structural precedence.** Ruby singleton/class and instance graphs remain separate, and existing RuboCop structural groups remain intact. Compare the traversal after projecting it into those groups. Frontend imports, types, constants, React hooks, object properties, and unrelated statements remain in place.
- **Approved — no prose comments.** Hand-written executable source contains no prose comments, including explanatory, section, narration, TODO, and FIXME comments. Names, extraction, explicit flow, and tests carry intent.
- **Approved — narrow comment allowlist.** Permit only exact language or tool directives, shebangs, legal headers already required by the project, and generated metadata recognized by structure or excluded generated paths. Do not provide a general per-comment escape hatch.
- **Approved — source scope.** Comment enforcement covers RuboCop-included Ruby source plus JavaScript, JSX, TypeScript, TSX, and CSS under `app/frontend`. Existing generated frontend API paths stay excluded. Documentation and YAML configuration comments are outside this iteration.
- **Approved — diagnostics only.** Neither ordering checker autocorrects. Comment cleanup may remove comments mechanically, but a tool must not rewrite surrounding code.
- **Approved — strict final state.** Audit first, then remove all detected legacy violations in scope. Do not finish with baselines, offense fingerprints, broad file exclusions, or warning-only rules.
- **Approved — existing commands and CI.** `bundle exec rubocop` and `pnpm lint` remain authoritative stack commands; `bin/lint` and `bin/test` remain combined local gates. Pull-request CI runs both linters.
- **Approved — concise agent policy.** `AGENTS.md` names each invariant once and relies on the lint tools for details. Its current discretionary comment exception is removed. `CLAUDE.md` remains a symlink to `AGENTS.md`.
- **Approved — runtime neutrality.** Production edits are limited to source declaration movement and comment removal without changing inputs, outputs, side effects, timing, visibility, callback registration, or public APIs.

Current developer-facing behavior: both violation classes pass lint; comments depend on agent judgment; pull-request CI omits lint.

Proposed developer-facing behavior: violations fail local lint and pull-request CI with actionable diagnostics, and the checked-in source is clean under both policies.

## Contracts

### Domain Contract — Ruby source policy

- **Owner and boundary:** repository-local RuboCop cops loaded by `.rubocop.yml`; no application domain owner or request boundary changes.
- **State:** Ruby AST and parser comments are inspection inputs only; application state and persistence are unaffected.
- **Invariants:** same-owner methods follow corrected depth-first first-call order; covered hand-written Ruby contains no prose comments.
- **Ordering definitions:** analyze direct `def`, `def self.x`, and `class << self` definitions within each class or module owner. Keep instance and singleton methods separate.
- **Ordering edges:** count unqualified calls and explicit `self` calls only when the matching method is defined in the same owner and method kind. Inspect call sites lexically.
- **Traversal:** start from zero-incoming-edge declarations in source order; visit each callee subtree before the caller's next callee; then start from each earliest unvisited declaration. First encounter owns shared helpers. A visited set terminates cycles. Project the expected order into each RuboCop structural group before comparison.
- **Ignored edges:** inherited/framework calls, other receivers, `super`, `send`/`public_send`, symbol callbacks, aliases, generated methods, and metaprogramming.
- **Allowed comments:** recognized Ruby magic comments, shebangs, exact RuboCop/type/coverage directives, structurally recognized generated schema-information blocks, and exact required legal headers. Generated and excluded paths remain governed by existing RuboCop scope.
- **Commands:** not applicable — lint only.
- **Inspection and recovery:** offenses identify file, owner, and expected-before-actual relationship or disallowed comment. Repair ordering manually and remove prose without changing behavior.
- **Tests:** custom-cop specs own AST behavior and comment classification.

### Frontend Contract — frontend source policy

- **Owner:** adapter-independent ordering and comment-classification modules, exposed through a thin local Oxlint plugin; a small CSS comment check joins the same `pnpm lint` command.
- **Scope:** non-generated JavaScript, JSX, TypeScript, TSX, and CSS under `app/frontend`.
- **Ordering definitions:** same-scope function declarations, variable-bound functions and arrows, and class methods. Object-literal methods are excluded because property order can be observable.
- **Ordering edges:** direct identifier calls to same-owner declarations, JSX references to locally defined components, and direct `this.method()` class calls. Imports, other object properties, computed calls, callback references used only as values, and dynamic resolution do not create edges.
- **Traversal:** use the corrected zero-incoming-edge algorithm from the Domain Contract. For locally nested functions, the enclosing executable body is a synthetic root whose call sites rank its direct nested declarations. Check each lexical owner independently.
- **Allowed comments:** exact TypeScript, ESLint/Oxlint, formatter, coverage, bundler, and generated/legal directives. JSX block comments and ordinary line/block comments are prose and fail. CSS permits only exact required legal/generated directives; ordinary block comments fail.
- **Failure:** report the enclosing scope and expected-before-actual relationship or the disallowed comment through the normal nonzero frontend lint result.
- **Compatibility:** tests target adapter-independent logic first. If the pinned Oxlint plugin API cannot expose a required syntax or comment token, use a standalone local Node check from `pnpm lint` without changing the contract or adding a parser dependency.
- **Tests:** Vitest owns ordering logic, directive classification, CSS scanning, and one process-level lint fixture proving nonzero failure.

### Agent Contract

- Add one ordering line: “Keep local methods and functions in depth-first call-site order; the applicable lint gate defines and enforces the exact rule.”
- Replace the current comment section with one rule: “Do not add prose comments to code; use names, structure, and tests. Required directives and generated metadata are allowed only where the lint gate recognizes them.”
- Keep the existing Completion requirement to run applicable static checks; do not duplicate commands or algorithms beside these rules.

## Boundaries and non-goals

- Do not construct a runtime call graph or resolve dynamic dispatch.
- Do not use an LLM reviewer, agent-specific hook, editor plugin, or autocorrection as the authoritative gate.
- Do not reorder constants, imports, types, Rails macros, callbacks, React hooks, object properties, or unrelated statements.
- Do not change application behavior while repairing existing order.
- Do not enforce comment policy in documentation, YAML, generated frontend API files, vendored code, database files, or other paths already excluded from the applicable lint scope.
- Do not add a parser dependency unless the installed RuboCop and frontend APIs cannot satisfy an approved contract.

## Testing decisions

- **Ruby order fast seam — failing tests first:** one-level and multi-level traversal, multiple callees, zero-incoming roots, callee-before-caller failure, shared helpers, disconnected methods, cycles, visibility projection, class versus instance methods, `class << self`, explicit `self`, and ignored dispatch.
- **Ruby comments fast seam — failing tests first:** prose, inline prose, TODO/FIXME, magic comments, exact tool directives, schema blocks, malformed lookalikes, and no general suppression escape hatch.
- **Frontend order fast seam — failing tests first:** shared traversal cases plus declarations, arrows, nested synthetic roots, JSX component references, class `this` calls, imports, callback references, and object-literal exclusions.
- **Frontend comments fast seam — failing tests first:** line, block, JSX, directive, malformed-lookalike, and CSS comments.
- **Process integration — failing tests first:** representative RuboCop and frontend fixtures prove each rule is loaded and produces a nonzero command status.
- **Real-tree audit:** run all checks before cleanup; record exact offense counts and inspect representative model, concern, component, test, initializer, and stylesheet findings for false positives.
- **Behavior-neutral cleanup:** use existing focused application tests when moving definitions in behavior-bearing classes; comment-only removals require diff inspection and syntax/static checks.
- **Final verification:** run custom-cop specs, frontend rule tests, `mise exec -- bundle exec rubocop`, `mise exec -- pnpm lint`, `bin/lint`, and `git diff --check`. Verify pull-request CI contains explicit backend and frontend lint steps.

## Open proposals

None.
