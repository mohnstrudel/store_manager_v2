# Ticket Readiness

Use this contract to turn an approved spec into cold-session tickets without repeating product planning.

## Readiness gate

Before writing tickets, verify that:

- every approved spec decision belongs to at least one ticket;
- each behavior, write path, migration, and public contract has one clear ticket owner;
- blockers reflect real repository dependencies, and independently safe tickets are identified as parallel work;
- each ticket fits one fresh session and can be verified without completing a later ticket;
- the spec plus ticket contains enough context to start without rediscovering ownership or inspecting unrelated code;
- expected values come from approved examples or independent hand calculation, never from implementation output; and
- no ticket contains a product or architecture choice that the spec leaves open.

If any item fails, revise the slices. Return missing application behavior or architecture to `collaborative-planning` as one precise delta.

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

## Anchors

- `<path>:<current-line-range>` — <the behavior or test seam this currently owns>.

## Non-goals

- <Adjacent behavior this ticket must not absorb.>

## Focused verification

- `<exact focused command>` — <what it proves for this ticket>.
````

Verify every code and test anchor immediately before writing. Prefer a stable symbol or behavior name in the note so the implementer can relocate an anchor if earlier tickets shift its lines.

Focused verification contains only related specs and directly relevant static checks. Never put the complete repository gate in a ticket; the coordinating task owns that gate after all tickets are done.

## Conditional sections

Add only what the slice needs:

- **Worked example** — for calculations, allocation, normalization, transformations, or state transitions; derive expected values independently by hand.
- **Failure and recovery** — for retries, partial failure, idempotency, rollback, stale state, or interruption.
- **Migration and compatibility** — for expand-contract ordering, backfills, constraints, or mixed-version operation.
- **Contract example** — for public payloads, interfaces, normalization, errors, or acknowledgements.
- **UI states** — for loading, empty, error, accessibility, and interaction recovery behavior.
- **Coordination notes** — for shared files, sequencing hazards, or tickets that must not run in parallel.

## Final coverage audit

Compare the complete ticket set with the spec and report only gaps: omitted decisions, duplicate ownership, hidden dependencies, unverifiable slices, missing anchors or expected values, and tickets too large for one fresh session. Do not redesign an otherwise ready breakdown.
