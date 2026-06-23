# AGENTS.md

## Architecture

- For Rails domain work, use `rails-domain-architecture` SKILL.md.
- For frontend work, use `frontend-architecture` SKILL.md.
- For adding or changing an inline table-cell editor, use `inline-cell-editor` SKILL.md.

## Completion

Before declaring work complete, run the **full** suite — not just files touched in the current task:

- `PARALLEL_TEST_PROCESSORS=6 mise exec -- bin/parallel-rspec` — all RSpec examples must pass.
- `mise exec -- pnpm exec vitest run` — all Vitest tests must pass.
- `mise exec -- pnpm exec oxlint app/frontend` — zero errors (warnings are pre-existing and acceptable).
- `mise exec -- pnpm exec oxfmt --check app/frontend …` — no formatting violations.
- `mise exec -- pnpm exec tsc --noEmit` — zero type errors.

Do not stop until every check above is green. Update any affected tests when behaviour changes.

## Safety

- Do not modify secrets or environment files.
- Do not introduce new dependencies without justification.
