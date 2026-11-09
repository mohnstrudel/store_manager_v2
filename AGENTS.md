# AGENTS.md

## Workflow entry points

- For a new behavior-bearing or structurally uncertain change owned by the coordinating task, start with `collaborative-planning`; it owns specialist-skill loading, planning, approval, serialization judgment, and the implementation loop for work that stays in that task. Clearly mechanical changes proceed directly under Completion unless the user asks for planning.
- For an approved spec or ticket, start with `implement`. Do not reload or rerun `collaborative-planning` unless implementation discovers a new material decision. Read only the selected spec, ticket, affected code, and applicable specialist skills.
- For delegated research or review, follow only the assigned scope. Do not start planning, serialize work, implement, or delegate again unless the assignment explicitly requires it.
- For Rails domain work, use `rails-domain-architecture`.
- For frontend work, use `frontend-architecture`.
- For Rails test boundaries, test infrastructure, and shared contracts, use `rails-testing`.
- For adding or changing an inline table-cell editor, use `inline-cell-editor`.
- To record an approved plan as a spec in `.specs/`, use `to-spec`; to split it into implementation-ready tickets, use `to-tickets`; to execute or resume serialized work, use `implement`. Serialization keeps implementation contexts minimal; the judgment rule lives in `collaborative-planning` Handoff.
- To write a commit message, use `commit`.

## Guidance files

- `AGENTS.md` holds always-on rules and skills hold on-demand rules; nothing else carries project rules. State each rule in one place.
- Skills encode decisions, contracts, and gotchas, never facts an agent can discover by inspecting the repo.

## Communication

- Lead with the result and end with the one next action. Runbooks and instructions are numbered commands with expected output, no prose.
- For user-facing copy, follow `docs/plain-language/interface-text.md`.

## Source organization

- Keep local methods and functions in depth-first call-site order; the lint gate defines and enforces the exact rule.

## Completion

Choose the smallest verification set that could catch a plausible defect.

- Non-executable changes — documentation, skills, comments, formatting, and metadata: inspect the diff and run a relevant syntax or static check; no application tests.
- Mechanical code changes: use the narrowest relevant static check or focused test. A diff proving executable code unchanged is sufficient.
- Behavior, API, persistence, or user-interaction changes: run focused tests covering the changed contract plus applicable static checks. Add a test only when the contract lacks coverage.
- One ticket: run its Focused verification and checks required by its actual changes.
- Completed ticket set: verify affected integration points.

Run a full backend or frontend suite only when the user requests it, a release gate requires it, or the change affects shared infrastructure or a cross-cutting contract whose interaction risk cannot be bounded by focused checks. State the trigger. Run only the applicable stack:

- Backend: `mise exec -- bin/rspec --format progress --color` and `mise exec -- bundle exec rubocop`.
- Frontend: `mise exec -- pnpm exec vitest run`, `mise exec -- pnpm run lint`, `mise exec -- pnpm run format:check`, and `mise exec -- pnpm exec tsc --noEmit`.

Required checks must be green. Fix failures caused by the change; report unrelated failures.

## Code comments

- Do not add prose comments to code; use names, structure, and tests. Required directives and generated metadata are allowed only where the lint gate recognizes them.

## Safety

- Do not modify secrets or environment files.
- Do not introduce new dependencies without justification.
- A Sidekiq worker runs in development (`Procfile.dev`). Anything that calls `perform_later` — rake tasks, `bin/rails runner`, the console — executes immediately against the dev database and real external credentials; confirm with the user before running it.
