---
name: implement
description: "Coordinate execution or resumption of an approved timestamped, named .specs iteration or ticket. Use when serialized work already exists: resolve the target, enforce blockers and claims, load minimal context, run focused verification, update status, and report the frontier. Do not use for a new request that still needs planning."
---

# Implement

Coordinate one approved unit of serialized work without reconstructing its planning conversation.

## Workflow

1. Resolve the spec directory.
   - Use an explicitly named spec path or iteration directory exactly.
   - Otherwise select the lexicographically newest directory under `.specs/<feature-slug>/` that matches `YYYYMMDDTHHMMSSZ__<spec-slug>` (optional numeric collision suffix) and contains `spec.md`.
   - If none exists, return to `collaborative-planning`.
2. Select the unit of work.
   - No tickets: the spec is the single unit.
   - Tickets: read only the `Status` and `Blocked by` header lines; do not load the spec or ticket bodies yet.
   - No explicit ticket: report any `in progress` ticket and stop; otherwise take the lowest-numbered `todo` ticket whose blockers are all `done`.
   - Explicit ticket: reject it when blocked or when its coordination notes conflict with another active ticket; require an explicit resume or takeover request when it is `in progress`. Independent tickets may run in parallel.
3. Claim it: set a `todo` ticket to `in progress`, then read only that ticket, its verified anchors, affected code, and applicable specialist skills.
4. Classify the unit from its contract.
   - Investigation ticket: gather only the named evidence and record the required deliverable. Do not change application behavior or choose product or architecture.
   - Implementation ticket or unticketed spec: implement only the approved observable outcome and acceptance criteria, using the simplest existing repository pattern that satisfies them.
5. For each listed TDD case, write the failing test first, confirm it fails for the expected reason, then implement. One case at a time. When the contract documents that no fast seam exists, use its approved verification route instead of inventing another test layer.
6. Stop on new decisions.
   - Do not reload `collaborative-planning` or reopen approved decisions.
   - New material product or architecture decision: return that precise delta to the coordinating task and wait for the spec update.
   - Investigation the ticket did not name: stop the unit and return the precise uncertainty so `to-tickets` can create an investigation ticket. Never hide research inside implementation.
7. Finish: run the ticket's Focused verification plus checks required by its actual changes, check off acceptance criteria, and set the ticket to `done`. When no `todo` or `in progress` ticket remains, delete the spec iteration directory.

## Rules

- When the selected spec has no tickets, implement it as one unit, apply `AGENTS.md`'s risk-based completion policy once its required checks pass, then delete the spec iteration directory.
- Treat the approved outcome, acceptance criteria, non-goals, and required repository constraints as the scope boundary. Do not invent requirements or follow implementation suggestions that are not approved constraints.
- Add no speculative validation, retries, fallbacks, compatibility layers, abstractions, or edge-case handling. Each must trace to an acceptance criterion, approved constraint, or concrete repository requirement.
- Write self-explanatory code through precise names, cohesive units, and explicit flow.
- Remove code made obsolete by the approved change, but do not absorb unrelated cleanup or refactoring.
- Status lines and checked criteria are the shared coordination state for parallel sessions; keep them truthful at every step.
- An `in progress` ticket is a best-effort claim. Never take it over without an explicit resume or takeover request.
