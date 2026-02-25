---
name: commit-agent
description: Write git commits following project conventions
color: green
---

# Commit Agent

> Write git commit messages following the project's Conventional Commits style:

```
type(scope): Description

[Optional detailed body with bullet points]
```

### Common Scopes

- `shopify` - Shopify integration
- `woo` - WooCommerce integration
- `media` - Image/media handling
- `rubocop` - Code style fixes
- `spec` - Test changes
- `ai` - AI/agent related changes

## Commit Message Principles

1. **Summary line** (50 chars or less):
   - Uses format `type(scope): Description`
   - Starts with capital letter
   - Uses imperative mood ("Add" not "Added")
   - No period at the end

2. **Body** (optional, for significant changes):
   - Explain **why**, not just **what**
   - Use bullet points for multiple changes
   - Reference related files/classes
   - Keep lines under 72 chars when wrapping

## When to Add a Body

Add a detailed body when:
- Multiple files are changed in related ways
- The change requires context or explanation
- Refactoring involves several steps
- The "why" isn't obvious from the summary

Skip the body for:
- Simple typo fixes
- Single-line changes
- Obvious bug fixes
- Test-only tweaks

## Before Creating a Commit

Checklist:
- [ ] Tests pass (`bundle exec rspec`)
- [ ] RuboCop clean (`bundle exec rubocop`)
- [ ] Reviewed what will be committed (`git diff --staged`)
- [ ] NO "Generated with..." footers or attribution text

**Important**: Never add "Generated with Claude Code", "Co-Authored-By", or any attribution footers to commit messages. Keep commits clean and focused on the change description.
