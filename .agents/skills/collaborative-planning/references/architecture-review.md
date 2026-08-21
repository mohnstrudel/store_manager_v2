# Architecture Review

Use this reference for work that changes a public contract, persistence, lifecycle, authority boundary, cross-layer data flow, or integration protocol.

## Evidence and Ownership

- Ground each proposed field, type, function, event, storage rule, lifecycle rule, and authority rule in existing code or mark it as a decision requiring approval.
- Inspect existing mechanisms and relevant call sites before adding another mechanism with the same responsibility.
- Identify the authoritative source for each value. Do not derive domain identity, deduplication, or mutation authority from adjacent state unless it explicitly owns that meaning.
- Reuse an existing contract when its fields and authority are the same. Give a new contract a name only when it changes semantics, ownership, lifecycle, validation, serialization, or available commands.
- Prefer direct parameters over a wrapper object that has no independent validation, storage, serialization, lifecycle, or reusable contract meaning.

## Lifecycle and Boundaries

- Identify the state transition that authoritatively creates or removes ownership. Finalize resources at that transition rather than in a bypassable convenience method.
- Prefer one shared finalization rule with source-specific private cleanup only where implementation differs.
- Preserve the invariant when mirroring an architecture across layers; do not copy server persistence mechanics into a client projection without the same authority.
- Keep mutable operations in commands or owning use cases. Keep views, serializers, and projections stable and descriptive rather than mutation-shaped.
- Keep generic host mechanics in the host and domain semantics in the owning module.

## Public Contracts

- Map every public field or capability to a concrete flow, its implementing owner, and whether the flow exposes it now, later, or never.
- Keep contracts narrow by capability and caller need. Factor truly identical shared meaning instead of forcing unrelated behavior into a broad contract.
- Settle names, payloads, results, errors, normalization, idempotency, and acknowledgement or broadcast behavior before documenting or implementing an integration contract.

## Review Gate

Compare the approved plan with current code and real scenarios. Report only:

- blockers or concrete design risks;
- source-of-truth or authority leaks;
- parallel data flow or storage;
- public/private boundary violations;
- hidden lifecycle models; and
- remaining decisions needing approval.

Do not redesign a sufficient plan without a concrete blocker. Keep design documentation terse and limited to approved decisions.
