# AGENTS.md

## Workflow entry points

- For a new change owned by the coordinating task, start with `collaborative-planning`; it owns specialist-skill loading, planning, approval, serialization judgment, and the implementation loop for work that stays in that task.
- For an approved spec or ticket, start with `implement`. Do not reload or rerun `collaborative-planning` unless implementation discovers a new material decision. Read only the selected spec, ticket, affected code, and applicable specialist skills.
- For delegated research or review, follow only the assigned scope. Do not start planning, serialize work, implement, or delegate again unless the assignment explicitly requires it.
- For Rails domain work, use `rails-domain-architecture` SKILL.md.
- For frontend work, use `frontend-architecture` SKILL.md.
- For Rails test boundaries, test infrastructure, and shared contracts, use `rails-testing` SKILL.md.
- For adding or changing an inline table-cell editor, use `inline-cell-editor` SKILL.md.
- To record an approved plan as a spec in `.specs/`, use `to-spec`; to split it into implementation-ready tickets, use `to-tickets`; to execute or resume serialized work, use `implement`. Serialization keeps implementation contexts minimal; the judgment rule lives in `collaborative-planning` Handoff.

## Clear communication

- Lead with the result and follow [the clear-communication guides](docs/plain-language.md), applying the matching guide for architecture and plans, LLM conversations, or interface text.

## Completion

Choose the smallest verification set that could catch a plausible defect.

- Non-executable changes — documentation, skills, comments, formatting, and metadata: inspect the diff and run a relevant syntax or static check; no application tests.
- Mechanical code changes: use the narrowest relevant static check or focused test. A diff proving executable code unchanged is sufficient.
- Behavior, API, persistence, or user-interaction changes: run focused tests covering the changed contract plus applicable static checks. Add a test only when the contract lacks coverage.
- One ticket: run its Focused verification and checks required by its actual changes.
- Completed ticket set: verify affected integration points.

Run a full backend or frontend suite only when the user requests it, a release gate requires it, or the change affects shared infrastructure or a cross-cutting contract whose interaction risk cannot be bounded by focused checks. State the trigger. Run only the applicable stack:

- Backend: `mise exec -- bin/rspec --format progress --color` and `mise exec -- bundle exec rubocop`.
- Frontend: `mise exec -- pnpm exec vitest run`, `mise exec -- pnpm exec oxlint app/frontend`, `mise exec -- pnpm exec oxfmt --check app/frontend …`, and `mise exec -- pnpm exec tsc --noEmit`.

Required checks must be green. Fix failures caused by the change; report unrelated failures.

## External HTTP tests

- Tests run without live external network access.
- Use a VCR cassette for a representative provider exchange when testing method and URL construction, serialization, parsing, or payload compatibility.
- Use WebMock for exact request assertions and deterministic failures, timeouts, malformed responses, or minimal unit cases.
- Keep cassettes minimal and deterministic. Filter credentials, tokens, personal data, and unstable headers before committing them.

## Code comments

- Comments are not an implementation deliverable. Default to none.
- Add a comment only when it explains why a non-obvious constraint exists or preserves information that cannot be inferred from the code.
- Never narrate control flow or restate what the code does. Prefer clearer names, smaller functions, and structure that makes the code explain itself.
- Never write multi-line prose comments about rationale, trade-offs, or edge cases. If one short line cannot preserve the needed information, improve the design instead.

## Safety

- Do not modify secrets or environment files.
- Do not introduce new dependencies without justification.
