# Ticket Readiness

Use this contract to turn an approved spec into cold-session tickets without repeating product planning.

## Readiness gate

Before writing tickets, verify that:

- every approved spec decision and requirement belongs to at least one ticket;
- each behavior, write path, migration, and public contract has one clear ticket owner;
- implementation tickets are vertical slices that produce observable behavior through every required layer; any horizontal infrastructure or migration ticket states why no safe vertical slice is possible;
- blockers reflect real repository dependencies, and independently safe tickets are identified as parallel work;
- investigation or feasibility work has its own evidence-producing ticket and blocks affected implementation tickets instead of being hidden inside them;
- no ticket contains a product or architecture choice that the spec leaves open; resolve major questions through `collaborative-planning` before ticketing the affected work;
- each ticket fits one fresh session and can be verified without completing a later ticket;
- the spec plus ticket contains enough context to start without rediscovering ownership or inspecting unrelated code;
- every requirement owned by a ticket appears as an observable acceptance criterion, not only as prose in What to build, Anchors, or a conditional section;
- every behavior-bearing implementation ticket identifies its test-first cases and fast test seam, or explains why no fast seam exists and names the approved verification route;
- expected values come from approved examples or independent hand calculation, never from implementation output;
- tickets contain no speculative defensive work: validation, retries, fallbacks, compatibility layers, abstractions, and edge-case handling require an approved behavior or repository evidence; and
- tickets default to no implementation comments. A requested comment must explain why a non-obvious constraint exists or preserve information that cannot be inferred from code. Never request comments that narrate control flow, restate code, or substitute for clear names and structure.

If any item fails, revise the slices. Return missing application behavior or architecture to `collaborative-planning` as one precise delta. Create a separate investigation ticket for implementation uncertainty that can be resolved without choosing product behavior or architecture.

## Required ticket contract

````markdown
# <NN>. <Title>

Spec: ../spec.md
Status: todo
Blocked by: none

## What to build

<One observable outcome and its approved behavior. Keep code paths out of this section.>

## Acceptance criteria

- [ ] <Observable result, not an implementation step.>

## TDD cases

- `<behavior case>` — `<fast test seam>`; write the failing test before implementation and confirm it fails for the expected reason.

## Anchors

- `<path>:<current-line-range>` — <the behavior or test seam this currently owns>.

## Non-goals

- <Adjacent behavior this ticket must not absorb.>

## Focused verification

- `<exact focused command>` — <what it proves for this ticket>.
````

Verify every code and test anchor immediately before writing. Prefer a stable symbol or behavior name in the note so the implementer can relocate an anchor if earlier tickets shift its lines.

Every acceptance criterion must trace to an approved requirement or necessary repository constraint. Do not bury requirements in descriptive sections. Do not add defensive scope or comments without that trace. A comment is never an implementation deliverable unless its non-inferable rationale or constraint is itself required.

Include TDD cases for behavior-bearing implementation tickets. Omit the section for mechanical or investigation tickets. When no fast seam exists, replace it with one sentence naming the approved verification route and why test-first does not apply.

Focused verification contains only related specs and directly relevant static checks. The coordinating task decides whether combined integration risk requires a complete backend or frontend suite.

## Conditional sections

Add only what the slice needs:

- **Worked example** — for calculations, allocation, normalization, transformations, or state transitions; derive expected values independently by hand.
- **Failure and recovery** — for retries, partial failure, idempotency, rollback, stale state, or interruption.
- **Migration and compatibility** — for expand-contract ordering, backfills, constraints, or mixed-version operation.
- **Contract example** — for public payloads, interfaces, normalization, errors, or acknowledgements.
- **UI states** — for loading, empty, error, accessibility, and interaction recovery behavior.
- **Coordination notes** — for shared files, sequencing hazards, or tickets that must not run in parallel.
- **Investigation output** — for a dedicated uncertainty ticket; name the question, evidence to gather, decision owner, and implementation tickets it unblocks. The ticket must not include implementation.

## Final coverage audit

Compare the complete ticket set with the spec and report only gaps: omitted decisions or requirements, duplicate ownership, hidden dependencies, unverifiable slices, unjustified horizontal tickets, implementation tickets that hide investigation, unresolved product or architecture questions, missing anchors or expected values, missing test-first cases, speculative defensive bloat, unnecessary or code-narrating comments, and tickets too large for one fresh session. Do not redesign an otherwise ready breakdown.
