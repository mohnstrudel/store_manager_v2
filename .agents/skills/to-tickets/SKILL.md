---
name: to-tickets
description: Turn an approved spec iteration into dependency-ordered, implementation-ready tickets. Use when collaborative planning chooses ticket serialization or the user asks to slice an approved spec; own ticket boundaries, dependencies, cold-context sufficiency, and focused verification without deciding application behavior or architecture.
---

# To Tickets

## Workflow

1. Resolve the approved spec. Use an explicitly named spec path or iteration directory exactly; otherwise select the lexicographically newest directory under `.specs/<feature-slug>/` whose name matches `YYYYMMDDTHHMMSSZ__<spec-slug>` with an optional numeric collision suffix and that contains `spec.md`. If none exists, return to `collaborative-planning` to create or select a spec.
2. Read [ticket-readiness.md](references/ticket-readiness.md) completely. Inspect the spec, current code, tests, and applicable specialist guidance; ticket sizes and blockers come from repository evidence, not the spec alone.
3. Draft dependency-ordered vertical slices. Each implementation ticket should deliver one observable behavior through every layer it needs and be independently verifiable in one fresh session. Use a horizontal ticket only when repository evidence shows that shared infrastructure or migration work cannot produce a safe vertical outcome; state that reason. Map every approved spec decision to at least one ticket, and identify shared-file conflicts and safe parallel work.
4. Ask only questions whose answers change ticket ownership, sequencing, size, independence, or verification. Recommend a boundary. Do not reopen settled decisions or invent application behavior.
5. Return every unresolved major product or architecture question to `collaborative-planning` before creating affected implementation tickets. Update the spec after approval, then resume ticketing.
6. Separate implementation uncertainty from implementation. When repository investigation or a feasibility check must happen first, create a dedicated investigation ticket with a concrete evidence deliverable and make affected implementation tickets depend on it. Do not hide research inside an implementation ticket. If the investigation may choose product behavior or architecture, resolve that question through `collaborative-planning` instead.
7. Present the numbered breakdown with outcomes, blockers, and parallelism. Obtain user approval before writing files.
8. Write tickets to `<spec-directory>/tickets/<NN>-<slug>.md` using the adaptive contract. Audit the complete set for omitted decisions, duplicate ownership, hidden dependencies, oversized tickets, speculative defensive bloat, unnecessary comments, and missing test-first cases before finishing.

Use a fresh-context readiness reviewer only when the user asks or the ticket set is unusually risky. Do not make review a routine ticketing step.
