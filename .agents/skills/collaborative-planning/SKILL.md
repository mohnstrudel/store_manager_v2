---
name: collaborative-planning
description: Create a collaborative, evidence-based plan for a new change owned by the coordinating task. Use before an unsolved implementation, refactor, bug fix, design change, documentation change, or skill update; ask focused questions, set boundaries, obtain approval for material decisions, and coordinate bounded reviews. Do not use for executing an approved spec or ticket, or for bounded delegated research or review.
---

# Collaborative Planning

Run the planning process with the user while applicable specialist skills supply domain-specific evidence and implementation rules. Treat existing code and explicit user decisions as evidence; distinguish facts, inferences, proposals, and approved decisions.

## Workflow

1. Load every applicable specialist skill before gathering detailed evidence. Keep all relevant specialist skills active for cross-layer work.
2. Inspect the relevant instructions, code, tests, contracts, and existing mechanisms.
3. Classify the affected paths with the gates below. Complete any conditional architecture review before the applicable specialist gates or contracts.
4. Complete the specialist gates or contracts, then share a visible plan with the goal, scope, affected boundaries, evidence, recommended approach, alternatives when material, validation strategy, and non-goals. For a material architecture decision, sketch two structurally different approaches with concrete tradeoffs before recommending one.
5. Mark each statement as a fact, inference, proposal, or approved decision when that distinction matters.
6. Ask focused questions only when an answer changes behavior, architecture, public contracts, persistence, lifecycle, or scope. State reasonable assumptions for everything else.
7. The user approves material behavior, architecture, contract, persistence, lifecycle, or authority decisions. A concise plan is enough for a mechanical task with no such decision.

## Behavior and Architecture Gates

Classify each affected path before implementation:

- **Mechanical:** preserves inputs, outputs, side effects, timing, and ordering.
- **Behavior-bearing:** may change outputs, validation, accepted inputs, side effects, timing, invalidation, caching, stale-state visibility, or user interaction.

List the current behavior, proposed behavior, affected scenario, and reason for every behavior-bearing path. Do not treat a broad refactor request as approval to change those semantics.

Read [architecture-review.md](references/architecture-review.md) before completing specialist gates or presenting a plan that introduces or changes a public contract, persistence, lifecycle, authority boundary, cross-layer data flow, integration protocol, or security boundary. Apply its relevant decisions through the applicable specialist gate or contract.

## Review Delegation

Apply the behavior and architecture gates before delegating; the reviewer is a second check, not a replacement for repository inspection.

Skip review for mechanical work unless the user asks for it. Use one fresh-context reviewer when the user asks or the plan changes material behavior, a public contract, persistence, lifecycle, authority, cross-layer data flow, an integration protocol, or a security boundary. A broad refactor is not automatically design-sensitive; classify its affected paths first.

Assign a concrete review lens from the actual risk, such as ownership and boundaries, behavior and edge cases, integration and security, or plan-blocking feasibility and validation. Do not rely on a generic job title to create useful review.

Give the reviewer the task, relevant code and contracts, the draft plan, and approved decisions. Its reporting contract is the Review Gate in [architecture-review.md](references/architecture-review.md), plus evidence-backed unsupported assumptions and missing material behavior scenarios.

Do not let the reviewer edit files, implement, reopen approved decisions without a concrete blocker, or redesign a sufficient plan. Use one reviewer and one pass by default. Use at most two reviewers when a second, independent high-risk lens is necessary, and do not allow nested delegation.

Verify each finding against the repository, revise the plan, and show the user material review-driven changes and unresolved decisions. Mention a rejected finding only when the disagreement matters. Stop reviewing when no material finding remains.

## Handoff

After approval, implement work that stays in the coordinating task under the same applicable specialist skills.

Judge serialization at approval using the path classification above; do not ask the user. Mechanical work gets no spec or tickets. For behavior-bearing work, default to `to-spec`: the spec lets implementation run on minimal context — spec and ticket instead of conversation history — and keeps approved decisions durable. Skip it only when the change and its verification clearly finish inside the current session. Add `to-tickets` when the work splits into more than one independently verifiable slice; one ticket plus the spec must be enough context for a fresh session. State the judgment in one line. The spec file is the durable record of approved decisions, updated whenever a delta gains approval.

Route serialized work through `implement`. Ticket tasks do not reload this skill or reconstruct the planning conversation. If implementation discovers a new material decision, return only that delta to the coordinating task, update the spec after approval, and then resume.

Preserve approved decisions and validate proportionately to the files and runtime behavior changed. Continue through mechanical discoveries without restarting planning.

## Implementation Loop

- On a behavior-bearing path with a fast test seam — model, request, or component tests — write the failing test first, at the seam agreed in the contract's Tests label, and watch it fail for the right reason before implementing. Work one slice at a time. Mechanical work and slow browser specs stay outside the loop; add browser coverage afterward when the frontend testing reference's risk criteria call for it.
- Take expected values from independent sources — known literals or worked examples. Never recompute them with the implementation's own logic or paste observed output as the expectation.
- Never weaken an assertion, mock away failing behavior, or special-case the implementation to make a test pass. A test that seems wrong is a decision to surface, not silently fix.
