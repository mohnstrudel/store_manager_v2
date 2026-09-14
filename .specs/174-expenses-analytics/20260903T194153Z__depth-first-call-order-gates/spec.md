# Depth-first call-order gates

## Problem

Ruby and TypeScript linting currently accept local methods and functions in any declaration order. Agents can therefore produce files whose implementation cannot be read in the same depth-first order as its call sites. `AGENTS.md` requires applicable lint checks, but pull-request CI currently runs tests without RuboCop or Oxlint, so local enforcement can be bypassed.

Long prompt instructions are not the preferred source of truth. Current OpenAI guidance recommends lean prompts, stating each rule once, and retaining style guidance when it encodes a requirement or corrects an observed failure. Current Anthropic guidance recommends short repository instructions and deterministic checks for requirements that must hold without exceptions. `CLAUDE.md` already links to `AGENTS.md`, so one concise repository rule can serve both agent families.

Evidence:

- `.rubocop.yml` already enforces structural method groups through `Layout/ClassStructure`; RuboCop 1.88 and `rubocop-ast` are installed.
- `.oxlintrc.json` and `package.json` already make Oxlint the frontend lint entry point; TypeScript is also installed.
- `bin/lint` and `bin/test` already run both lint stacks.
- `.github/workflows/tests.yml` runs RSpec and Vitest but not RuboCop or Oxlint.
- Oxlint supports local ESLint-compatible JavaScript plugins, but the plugin API is currently alpha and not covered by semantic-version guarantees.
- OpenAI model guidance: https://developers.openai.com/api/docs/guides/latest-model
- Anthropic Claude Code best practices: https://code.claude.com/docs/en/best-practices
- Oxlint JavaScript plugin guidance: https://oxc.rs/docs/guide/usage/linter/js-plugins

## Goal and approach

Add deterministic backend and frontend checks for depth-first call-site declaration order, integrate them into the repository's existing lint commands and pull-request CI, and give agents one short instruction naming the invariant. The tools own the detailed algorithm and diagnostics.

Observable success:

- A Ruby or frontend fixture ordered `A, B, D, C` passes when `A` calls `B` then `C`, and `B` calls `D`.
- Reordering that fixture to `A, B, C, D` fails with a diagnostic that identifies the expected relationship.
- Both checks terminate and behave deterministically for shared helpers and recursive cycles.
- The normal backend and frontend lint commands run the checks.
- Pull-request CI fails when either check fails.
- The final strict configuration has no silent whole-file exclusions.

## Approved decisions

- **Approved — two executable checks.** Backend Ruby and frontend TypeScript/TSX receive language-specific implementations of the same ordering contract.
- **Approved — deterministic authority.** Executable lint results, not agent judgment, decide whether declaration order is acceptable.
- **Approved — existing entry points.** The backend check runs under RuboCop; the frontend check runs under the existing `pnpm lint` entry point. `bin/lint` and `bin/test` remain the combined local gates.
- **Approved — pull-request gate.** CI runs the applicable backend and frontend lint commands in addition to tests.
- **Approved — diagnostics only.** Neither checker autocorrects declaration order. Reordering definitions can interact with Ruby visibility and class-body execution or JavaScript initialization, so the implementer fixes each offense with context.
- **Approved — structural precedence.** Existing language structure remains intact. Ruby class methods, initialization, public methods, protected methods, and private methods remain grouped; depth-first order applies within those groups and ranks private helpers from their public callers. Frontend imports, types, constants, and non-function declarations are not reordered by this rule.
- **Approved — static contract.** The tools enforce statically resolvable same-owner calls. They do not claim to reconstruct runtime dispatch.
- **Approved — runtime neutrality.** This change must not alter application behavior; production-code movement is limited to declaration reordering needed to satisfy the gate.

Current developer-facing behavior: unordered local declarations pass lint, and pull-request CI does not run the lint stacks.

Proposed developer-facing behavior: statically detectable depth-first order violations fail local lint and pull-request CI with actionable diagnostics.

## Contracts

### Domain Contract — Ruby ordering

- **Owner:** a repository-local RuboCop cop loaded by `.rubocop.yml`.
- **Scope:** Ruby files already included by RuboCop, including application code and specs.
- **Definitions:** instance methods and singleton/class methods are analyzed separately within each class or module owner.
- **Calls:** unqualified calls and explicit `self` calls count only when a matching method is defined on the same owner and method kind.
- **Traversal:** inspect calls in lexical order. Starting from public methods in source order, visit each same-owner callee before the caller's next callee. Then visit any unvisited methods in source order. Compare relative order within each structural group.
- **Shared helpers and cycles:** the first traversal encounter owns placement; already visited methods are not revisited.
- **Ignored dispatch:** inherited calls, calls on other receivers, `send`/`public_send`, symbol callbacks, aliases, generated methods, and other metaprogramming do not create ordering edges.
- **Failure:** report the owner and the smallest useful caller/callee or expected-before-actual relationship; exit through RuboCop's normal nonzero status.

### Frontend Contract — TypeScript and TSX ordering

- **Owner:** repository-local ordering logic exposed through a thin Oxlint-compatible JavaScript plugin adapter.
- **Scope:** TypeScript and TSX files under `app/frontend`, including tests.
- **Definitions:** same-scope function declarations, functions or arrow functions bound to variables, and class methods are analyzed in separate lexical owners. Object-literal methods are excluded because property order can be observable.
- **Calls:** direct identifier calls to a definition in the same lexical owner count. JSX references to a locally defined component count as call sites. Class methods count direct `this.method()` calls to methods on the same class.
- **Traversal:** use the same lexical, depth-first, first-encounter semantics as the Ruby contract. Exported/module entry functions are roots in source order, followed by unvisited declarations in source order. Nested lexical owners are checked independently.
- **Shared helpers and cycles:** the first traversal encounter owns placement; already visited functions are not revisited.
- **Ignored dispatch:** imported functions, property calls on other objects, computed calls, callbacks referenced only as values, dynamically selected functions, and runtime type resolution do not create ordering edges.
- **Failure:** report the enclosing scope and the smallest useful expected-before-actual relationship; exit through Oxlint's normal nonzero status.
- **Compatibility:** keep traversal and ordering logic independent of the Oxlint adapter and test it directly. This limits exposure to Oxlint's alpha plugin API.

### Agent Contract

- `AGENTS.md` remains the single shared repository instruction source; `CLAUDE.md` continues to link to it.
- The detailed algorithm, examples, exceptions, and repair guidance live in checker tests and diagnostics, not in the always-loaded agent prompt.
- The existing Completion section remains responsible for selecting and running applicable lint checks.

## Boundaries and non-goals

- Do not build a runtime call graph or resolve dynamic dispatch.
- Do not add an LLM-based reviewer or use an agent as the enforcement mechanism.
- Do not add editor-specific, Claude-specific, or Codex-specific hooks as the authoritative gate.
- Do not autocorrect or silently move declarations.
- Do not reorder constants, imports, types, Rails macros, React hooks, object properties, or unrelated statements.
- Do not add a new parser dependency unless implementation proves the installed RuboCop/Oxlint APIs cannot satisfy an approved contract.
- Do not add or change the separate code-comment policy in this iteration.

## Testing decisions

- **Backend fast seam — failing test first:** custom-cop specs cover one-level order, multi-level depth-first order, multiple callees, shared helpers, recursion/cycles, disconnected methods, visibility groups, class versus instance methods, explicit `self`, external receivers, and dynamic dispatch exclusions.
- **Frontend fast seam — failing test first:** direct ordering-logic tests cover the shared cases plus function declarations, variable-bound functions, nested scopes, JSX component references, class `this` calls, imports, and object-literal exclusions.
- **Frontend adapter seam — failing test first:** one integration fixture proves Oxlint loads the local plugin, emits the rule diagnostic, and exits nonzero.
- **Real-tree audit:** run both rules over their full scopes before changing production declarations. Record offense counts and inspect representative results for false positives.
- **Focused verification:** run the backend cop specs, frontend rule tests, and intentionally passing/failing fixtures.
- **Integration verification:** run `mise exec -- bundle exec rubocop`, `mise exec -- pnpm lint`, and `bin/lint`; inspect the workflow diff and run syntax/static validation for its configuration.
- **Final-state verification:** both lint stacks pass without whole-file exclusions, and CI contains explicit backend and frontend lint steps.

## Open proposals

- **Proposal — concise agent wording (recommended):** add one line to `AGENTS.md`: “Keep local methods and functions in depth-first call-site order; the applicable lint gate defines and enforces the exact rule.” This is enough to help agents avoid a repair cycle while leaving details to deterministic tooling. A tools-only approach saves one line but hides an unusual repository convention until lint fails; a long algorithm duplicates the tools and consumes persistent context.
- **Proposal — frontend adapter (recommended):** use an Oxlint JavaScript plugin so `pnpm lint` stays the single frontend command, while keeping the algorithm in an adapter-independent module because Oxlint marks this API alpha. Fall back to a standalone TypeScript-based command wired into `pnpm lint` only if a prototype demonstrates an Oxlint API blocker.
- **Proposal — legacy migration (recommended):** finish with a strict clean tree in the same implementation effort. First audit offense volume; if cleanup is too large for a reviewable change, pause and approve a second iteration with precise offense fingerprints as a temporary ratchet. Do not use broad file exclusions.
