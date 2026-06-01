# AGENTS.md

## Architecture

- For Rails domain work, use `rails-domain-architecture` SKILL.md.
- For frontend work, use `frontend-architecture` SKILL.md.

## Completion

Before declaring work complete:

- Lint every changed file relevant to the work.
- For frontend changes, run the relevant oxlint command, including React performance rules.
- Run relevant tests.
- Update affected tests when behavior changes.
- Do not leave failing tests.

## Safety

- Do not modify secrets or environment files.
- Do not introduce new dependencies without justification.
