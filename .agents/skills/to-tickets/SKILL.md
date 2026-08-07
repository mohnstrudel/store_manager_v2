---
name: to-tickets
description: Turn an approved spec iteration into dependency-ordered, implementation-ready tickets. Use when collaborative planning chooses ticket serialization or the user asks to slice an approved spec; own ticket boundaries, dependencies, cold-context sufficiency, and focused verification without deciding application behavior or architecture.
---

# To Tickets

## Workflow

1. Resolve the approved spec. Use an explicitly named spec path or iteration directory exactly; otherwise select the lexicographically newest directory under `.specs/<feature-slug>/` whose name matches `YYYYMMDDTHHMMSSZ__<spec-slug>` with an optional numeric collision suffix and that contains `spec.md`. If none exists, return to `collaborative-planning` to create or select a spec.
2. Read [ticket-readiness.md](references/ticket-readiness.md) completely. Inspect the spec, current code, tests, and applicable specialist guidance; ticket sizes and blockers come from repository evidence, not the spec alone.
3. Draft dependency-ordered vertical slices. Map every approved spec decision to at least one ticket, identify shared-file conflicts and safe parallel work, and keep each slice independently implementable and verifiable in one fresh session.
4. Ask only questions whose answers change ticket ownership, sequencing, size, independence, or verification. Recommend a boundary. Do not reopen settled decisions or invent application behavior.
5. If a material behavior or architecture rule is missing, pause only the affected slice and return that precise delta to `collaborative-planning`. Update the spec after approval, then resume ticketing.
6. Present the numbered breakdown with outcomes, blockers, and parallelism. Obtain user approval before writing files.
7. Write tickets to `<spec-directory>/tickets/<NN>-<slug>.md` using the adaptive contract. Audit the complete set for omitted decisions, duplicate ownership, hidden dependencies, and oversized tickets before finishing.

Use a fresh-context readiness reviewer only when the user asks or the ticket set is unusually risky. Do not make review a routine ticketing step.
