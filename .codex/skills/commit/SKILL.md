---
name: commit
description: Use when asked to write a git commit for this repo. The only repo-specific guidance is the Conventional Commit format, common scopes, and avoiding attribution footers.
---

# Commit

Write commits in this format:

```text
type(scope): Description
```

## Rules

- Do not add AI attribution, co-author lines, or generated-by footers.
- Use the `ai` scope only for changes that are actually about AI behavior, AI tooling, or AI-specific repo features. Do not use `ai` just because Codex made the change.

## Common scopes

`shopify`, `woo`, `media`, `rubocop`, `spec`, `ai`
