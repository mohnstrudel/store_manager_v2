# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Memory

Project-specific memories (conventions, feedback, decisions) live in `.claude/memory/`. Read `.claude/memory/MEMORY.md` at the start of any session for the index, then load individual files as relevant.

## Authoritative docs

- [AGENTS.md](AGENTS.md) — repo-specific refactor rules, placement guide, and skill index. The "Refactor Rules" and "Placement Guide" sections are the canonical short form.

## Commands

Always prefix Ruby/Rails/RSpec with `mise exec --` so the active runtime comes from `mise`, not the shell PATH:

```bash
mise exec -- bin/dev
mise exec -- bin/rspec spec/models/product/editing_spec.rb
PARALLEL_TEST_PROCESSORS=6 mise exec -- bin/parallel-rspec
```

## UI changes need tests

Frontend tests default to **component tests**. Use a Cuprite browser spec only when the risk lives in actual browser behavior: dialogs, keyboard navigation, focus management, file uploads, drag and drop, layout-sensitive behavior, or multi-step workflows. Either way, tests are part of the implementation, not a polish step.

## Commits

Conventional Commits, no AI attribution footers:

```
type(scope): description
```
