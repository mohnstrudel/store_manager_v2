---
name: to-tickets
description: Turn an approved spec iteration into dependency-ordered, implementation-ready tickets. Use when collaborative planning chooses ticket serialization or the user asks to slice an approved spec; own ticket boundaries, dependencies, cold-context sufficiency, and focused verification without deciding application behavior or architecture.
---

# To Tickets

## Workflow

1. Resolve the approved spec.
   - Use an explicitly named spec path or iteration directory exactly.
   - Otherwise select the lexicographically newest directory under `.specs/<feature-slug>/` that matches `YYYYMMDDTHHMMSSZ__<spec-slug>` (optional numeric collision suffix) and contains `spec.md`.
   - If none exists, return to `collaborative-planning` to create or select one.
2. Read [ticket-readiness.md](references/ticket-readiness.md) completely, then the spec, current code, tests, and applicable specialist guidance. Ticket sizes and blockers come from repository evidence, not the spec alone.
3. Draft dependency-ordered vertical slices.
   - Each implementation ticket delivers one observable behavior through every layer it needs and is verifiable in one fresh session.
   - Use a horizontal ticket only when repository evidence shows shared infrastructure or migration work cannot produce a safe vertical outcome; state that reason.
   - Map every approved spec decision to at least one ticket.
   - Mark shared-file conflicts and safe parallel work.
4. Separate uncertainty from implementation: when repository investigation or a feasibility check must happen first, create a dedicated investigation ticket with a concrete evidence deliverable and make affected implementation tickets depend on it. If the investigation may choose product behavior or architecture, resolve that through `collaborative-planning` instead.
5. Ask only questions whose answers change ticket ownership, sequencing, size, independence, or verification, and recommend a boundary with each. Do not reopen settled decisions or invent application behavior. Return unresolved product or architecture questions to `collaborative-planning`, update the spec after approval, then resume.
6. Present the numbered breakdown with outcomes, blockers, and parallelism. Get user approval before writing files.
7. Write tickets to `<spec-directory>/tickets/<NN>-<slug>.md` using the ticket contract, then audit the set for omitted decisions, duplicate ownership, hidden dependencies, oversized tickets, speculative defensive bloat, and missing test-first cases.

Use a fresh-context readiness reviewer only when the user asks or the ticket set is unusually risky.
