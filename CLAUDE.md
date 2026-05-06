# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Authoritative docs

- [README.md](README.md) — full architecture, business record map, request flow examples, and "Where to put new code" placement guide. Read this before non-trivial changes.
- [AGENTS.md](AGENTS.md) — repo-specific refactor rules, placement guide, and skill index. The "Refactor Rules" and "Placement Guide" sections are the canonical short form.
- `.codex/skills/rails-domain-architecture/references/` — deeper guidance referenced from AGENTS.md (`task-router.md`, `principles.md`, `full-stack-architecture.md`, `jobs-architecture.md`, `screen-first-view-pattern.md`, `testing-architecture.md`).

## Commands

Always prefix Ruby/Rails/RSpec with `mise exec --` so the active runtime comes from `mise`, not the shell PATH:

```bash
mise exec -- bin/dev
mise exec -- bin/rspec spec/models/product/editing_spec.rb
PARALLEL_TEST_PROCESSORS=6 mise exec -- bin/parallel-rspec
```

## UI changes need browser specs

For risky UI work (loading skeletons, dialogs, gallery transitions, layout stability), add or update a Cuprite feature spec — it's part of the implementation, not a polish step.

## Commits

Conventional Commits, no AI attribution footers:

```
type(scope): description
```
