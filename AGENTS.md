# AGENTS.md

## Workflow entry points

- For a new change owned by the coordinating task, start with `collaborative-planning`; it owns specialist-skill loading, planning, approval, serialization judgment, and the implementation loop for work that stays in that task.
- For an approved spec or ticket, start with `implement`. Do not reload or rerun `collaborative-planning` unless implementation discovers a new material decision. Read only the selected spec, ticket, affected code, and applicable specialist skills.
- For delegated research or review, follow only the assigned scope. Do not start planning, serialize work, implement, or delegate again unless the assignment explicitly requires it.
- For Rails domain work, use `rails-domain-architecture` SKILL.md.
- For frontend work, use `frontend-architecture` SKILL.md.
- For adding or changing an inline table-cell editor, use `inline-cell-editor` SKILL.md.
- To record an approved plan as a spec in `.specs/`, use `to-spec`; to split it into implementation-ready tickets, use `to-tickets`; to execute or resume serialized work, use `implement`. Serialization keeps implementation contexts minimal; the judgment rule lives in `collaborative-planning` Handoff.

## Clear communication

- Lead with the result and follow [the clear-communication guides](docs/plain-language.md), applying the matching guide for architecture and plans, LLM conversations, or interface text.

## Completion


Validate in proportion to what changed.

For one ticket, run only the specs and directly relevant static checks for what that ticket changed, using its Focused verification section. Do not run the full application suite from a ticket task.

After every ticket is done, the coordinating task runs the **full** suite. A task implementing a spec without tickets, or application work that was not ticketed, also runs this gate before completion:

- `mise exec -- bin/rspec --format progress --color` — all RSpec examples must pass.
- `mise exec -- pnpm exec vitest run` — all Vitest tests must pass.
- `mise exec -- pnpm exec oxlint app/frontend` — zero errors (warnings are pre-existing and acceptable).
- `mise exec -- pnpm exec oxfmt --check app/frontend …` — no formatting violations.
- `mise exec -- pnpm exec tsc --noEmit` — zero type errors.

For documentation, skills, and other non-executable project metadata, do not run the application suite. Validate the changed artifact, check the diff, and run only a directly relevant static check when one exists.

Do not stop until the required verification is green. During the final gate, investigate and fix every failure even when it appears pre-existing or unrelated. Update any affected tests when behaviour changes.

## Code comments

- Default to no comments. Only add one when the WHY is genuinely non-obvious from the code itself: a hidden constraint, a subtle invariant, a workaround for a specific bug.
- Never write multi-line comment blocks narrating rationale, trade-offs, or edge cases in prose. If a comment needs more than one short line, the design likely needs a clearer name or a smaller function instead.
- Do not restate what the code already says. If removing the comment wouldn't confuse a future reader, don't write it.

## Safety

- Do not modify secrets or environment files.
- Do not introduce new dependencies without justification.
