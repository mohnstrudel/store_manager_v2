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
4. Implement the settled outcome. Do not reload `collaborative-planning` or reopen approved decisions. If a new material decision appears, return that precise delta to the coordinating task and wait for the spec to be updated.
5. Run only the ticket's Focused verification plus checks directly relevant to its actual changes — never the full `AGENTS.md` gate, another ticket's checks, or a check that already passed unchanged. Check off acceptance criteria only after verification, set the ticket to `done`, then make one commit for the ticket's changes using the `commit` skill's format.
6. Report the next frontier. When every ticket is `done`, run the full `AGENTS.md` verification gate if this is the coordinating task; otherwise report that requirement to the coordinating task and stop.

## Rules

- When the selected spec has no tickets, implement it as one unit, run the full `AGENTS.md` verification gate before completion, and make one commit for the unit once the gate passes.
- Status lines and checked criteria are the shared coordination state for parallel sessions; keep them truthful at every step.
- An `in progress` ticket is a best-effort claim. Never take it over without an explicit resume or takeover request.
- Commit only after the ticket's (or unit's) verification passes, one commit per ticket or unit, scoped to only its changes — never bundle multiple tickets, unrelated files, or a failing state into one commit.
