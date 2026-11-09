---
name: commit
description: Use when asked to write a git commit for this repo. Conventional Commit subject with a capitalized imperative description and a scope taken from recent history.
---

# Commit

```text
type(scope): Capitalized imperative description
```

- Types: `feat`, `fix`, `refactor`, `style`, `test`, `docs`, `chore`, `perf`.
- Scope is the domain or layer touched; match recent `git log` (`sales`, `frontend`, `variants`, `spec`, `shopify`, `products`). Omit it for cross-cutting changes.
- Add a body only when the subject cannot carry the reason.
