---
name: to-spec
description: Serialize the current conversation's plan into a new timestamped, named local spec iteration under .specs/. The spec records approved decisions from collaborative planning as the durable artifact that lets implementation run on minimal context. Use when the user invokes it, or when collaborative planning's serialization judgment calls for a spec — behavior-bearing work whose implementation should not carry the planning conversation.
---

# To Spec

Convert what this conversation has already settled into a new iteration under `.specs/<feature-slug>/<timestamp>__<spec-slug>/spec.md`. Do not interview the user; questions belong to `collaborative-planning`. Synthesize, mark status, and write the file.

## Rules

- `<feature-slug>` is the current git branch name used verbatim, including any `/` separators (branch `/variant-assignments` → `.specs/variant-assignments/`).
- Build `<spec-slug>` from an explicitly approved spec name or scope when present; otherwise derive it from the spec title. Use a concise, filesystem-safe lowercase kebab-case name that makes the directory's purpose visible without asking another question.
- Every invocation creates a new named iteration such as `20260803T142530Z__variant-assignment-repair`. If that path exists, append a numeric suffix to the slug (`-01`, `-02`, …) until the path is unused.
- Write the new spec to `.specs/<feature-slug>/<timestamp>__<spec-slug>/spec.md`. Never overwrite or update an earlier iteration; preserve it as history.
- Render the visible plan shape from `collaborative-planning` — goal, scope, affected boundaries, evidence, recommended approach, alternatives when material, validation strategy, and non-goals — do not invent another structure. Include the applicable Domain Contract and Frontend Contract labels.
- Mark every decision `approved` or `proposal`. Never promote a proposal silently; collect unresolved proposals under Open proposals.
- When a decision changes behavior, record current behavior and proposed behavior separately.
- Describe approved behavior concretely enough to derive acceptance cases, but do not prescribe every implementation detail. Name implementation constraints only when they are approved architecture, contract, compatibility, sequencing, or verification decisions.
- Record required behavior as observable outcomes, including boundaries and failure behavior that implementation tickets must preserve.
- In Testing decisions, list the behavior cases that need coverage and identify the fast seam for each case. Mark behavior-bearing cases that should enter the implementation loop as failing tests first.
- Reject speculative defensive work. Do not add validation, retries, fallbacks, compatibility layers, abstractions, or edge-case handling unless approved behavior or repository evidence requires it.
- Require self-explanatory implementation through names, cohesion, and explicit flow. Do not request comments unless indispensable rationale or an external constraint cannot be encoded or inferred and omitting it would create material misuse or regression risk.
- Keep the spec decision-dense and short. Skip narration, user stories, issue-tracker formatting.
- The spec is the reference for `to-tickets`, for implementing sessions, and for reviewing the result (`/code-review` against the spec).

## Template

```markdown
# <Feature title>

## Problem
## Goal and approach
## Approved decisions
## Contracts
## Boundaries and non-goals
## Testing decisions
## Open proposals
```

Omit a section only when it is genuinely empty, and keep Open proposals even when empty (`None`) so its absence is never ambiguous.
