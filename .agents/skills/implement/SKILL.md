---
name: implement
description: "Coordinate execution or resumption of an approved timestamped, named .specs iteration or ticket. Use when serialized work already exists: resolve the target, enforce blockers and claims, load minimal context, run focused verification, commit each completed unit, update status, and report the frontier. Do not use for a new request that still needs planning."
---

# Implement

Coordinate one approved unit of serialized work without reconstructing its planning conversation.

## Workflow

1. Resolve the spec directory. Use an explicitly named spec path or iteration directory exactly; otherwise select the lexicographically newest directory under `.specs/<feature-slug>/` whose name matches `YYYYMMDDTHHMMSSZ__<spec-slug>` with an optional numeric collision suffix and that contains `spec.md`. If none exists, return to `collaborative-planning`.
2. When tickets exist, read only each ticket's `Status` and `Blocked by` header lines — never full ticket bodies or the spec — to select a target. Without an explicit ticket, report any `in progress` ticket and stop; otherwise select the lowest-numbered `todo` ticket whose blockers are all `done`. When no tickets exist, read the spec itself as the single unit of work.
3. For an explicit ticket, require an explicit resume or takeover request when it is already `in progress`. Reject it when blocked or when its coordination notes conflict with another active ticket; otherwise independent tickets may run in parallel. Set a selected `todo` ticket to `in progress`, then read only that ticket, its verified anchors, affected code, and applicable specialist skills.
4. Classify the selected unit from its contract. For an investigation ticket, gather only the named evidence, record the required deliverable, and do not change application behavior or choose product or architecture. For an implementation ticket or unticketed spec, implement only the approved observable outcome and acceptance criteria, using the simplest existing repository pattern that satisfies them.
5. For each listed TDD case, write the failing test first and confirm it fails for the expected reason before implementing. Work one case at a time. When the contract documents that no fast seam exists, use its approved verification route instead of inventing another test layer.
6. Do not reload `collaborative-planning` or reopen approved decisions. If a new material product or architecture decision appears, return that precise delta to the coordinating task and wait for the spec to be updated. If implementation requires investigation not named by the ticket, stop the affected unit and return the precise uncertainty so `to-tickets` can create a separate investigation ticket; never hide research inside implementation.
7. Run the ticket's Focused verification plus checks required by its actual changes. Check off acceptance criteria after verification, set the ticket to `done`, then make one commit for the ticket's changes using the `commit` skill's format.
8. Report the next frontier. When every ticket is `done`, the coordinating task applies `AGENTS.md`'s risk-based completion policy to the combined change; other tasks report the frontier and stop.

## Rules

- When the selected spec has no tickets, implement it as one unit, apply `AGENTS.md`'s risk-based completion policy, and make one commit for the unit once its required checks pass.
- Treat the approved outcome, acceptance criteria, non-goals, and required repository constraints as the scope boundary. Do not invent requirements or follow implementation suggestions that are not approved constraints.
- Add no speculative validation, retries, fallbacks, compatibility layers, abstractions, or edge-case handling. Each must trace to an acceptance criterion, approved constraint, or concrete repository requirement.
- Write self-explanatory code through precise names, cohesive units, and explicit flow. Add one short comment explaining why only when indispensable rationale or an external constraint cannot be encoded or inferred and omitting it creates material misuse or regression risk.
- Remove code made obsolete by the approved change, but do not absorb unrelated cleanup or refactoring.
- Status lines and checked criteria are the shared coordination state for parallel sessions; keep them truthful at every step.
- An `in progress` ticket is a best-effort claim. Never take it over without an explicit resume or takeover request.
- Commit only after the ticket's (or unit's) verification passes, one commit per ticket or unit, scoped to only its changes — never bundle multiple tickets, unrelated files, or a failing state into one commit.
