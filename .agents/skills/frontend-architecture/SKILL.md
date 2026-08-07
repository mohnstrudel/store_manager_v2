---
name: frontend-architecture
description: Design or refactor React and Inertia frontend code with clear behavior owners, state sources, transitions, boundaries, recovery paths, and test ownership. Use for page composition, components, hooks, providers, local or browser state, frontend contracts, browser integrations, frontend refactors, test strategy, or styling architecture in this Rails app. Do not use alone when work changes backend models, controllers, jobs, routes, persistence, or domain workflows; also use `rails-domain-architecture`.
---

# Frontend Architecture

## Usage

- Use `collaborative-planning` to run the planning process. Use this skill while gathering frontend evidence and defining the plan, then keep it active through implementation and validation.
- Load `rails-domain-architecture` at the same time when work needs new backend data, routes, authorization, persistence, or domain behavior.
- Read [components.md](references/components.md) when adding a component or structurally refactoring a component or page. Routine content edits do not require the reference.
- Read [testing.md](references/testing.md) when adding or changing frontend tests, or when choosing a test strategy is part of the design. Routine verification of a mechanical change does not require the reference.
- Read [styling.md](references/styling.md) when work changes CSS, layout, responsive or dark-mode behavior, visual state, or presentation markup.
- Read `docs/plain-language/interface-text.md` when writing or changing user-facing copy: labels, buttons, errors, empty states, or confirmations.
- For a persisted table-cell editor, also use `inline-cell-editor`; it supplements this skill and the Rails skill.

## Example Policy

- **Repository convention:** Follow the shown shape unless the inspected owner has a more specific existing contract.
- **Illustration:** Apply the ownership or boundary decision without copying names or structure mechanically.

## Required Frontend Contract

Before planning behavior-bearing frontend work or a structural refactor that affects or calls into question ownership, state, authority, or boundaries, write every label. Write `Not applicable — <reason>` when a label genuinely does not apply. When collaborative planning loads `architecture-review.md`, incorporate its relevant lifecycle and public-contract decisions through these labels instead of creating another checklist:

- **Owner and boundary:** Name the page, component, hook, provider, or browser adapter that owns the behavior. Define its public props, context, hook, or adapter contract and dependency direction. Name the backend boundary when domain data or commands are involved.
- **State:** Name each authoritative source, its lifetime, and its permitted writers: backend props, URL, page, provider, component, or browser storage. Identify deterministic presentation values that remain derived.
- **Invariants:** State what must hold and whether the frontend owner, backend domain owner, authorization boundary, or browser platform enforces it. Do not copy backend domain invariants into React as another authority.
- **Commands and transitions:** Name the events and owner commands that move state. Include loading, success, empty, error, and stale transitions when relevant, and keep each write flow singular.
- **Inspection and recovery:** Explain how users and developers can see current, pending, stale, or failed state and safely retry, reset, refresh, or recover without hidden repair effects.
- **Tests:** Choose the narrowest user-visible seam. Cover invalid, stale, overlapping-request, browser-sensitive, and backend-contract scenarios when relevant.

## Implementation Path

1. Inspect current rendering, props, context, state writers, effects, requests, routes, styles, and tests. Treat current placement as evidence, not proof of correct ownership.
2. Start from the authoritative state source and one behavior owner. Derive only deterministic UI values; do not infer domain facts from names, IDs, adjacent props, or event payloads.
3. Place code by ownership and cohesion:
   - Pages own composition and the page contract.
   - Components own cohesive interaction and presentation.
   - Hooks own a distinct behavior, lifecycle, synchronization process, or external integration; do not extract a hook merely to shorten a component.
   - Providers own behavior shared by one subtree with a clear lifetime; prop depth alone does not justify Context.
   - Utilities remain pure and owner-neutral.
   - Adapters own browser or external protocols.
   - Shared components require proven reuse or a stable UI primitive. Keep page-owned UI near its page until that boundary exists.
4. Keep the frontend/backend boundary explicit. React owns presentation and interaction state; Rails owns domain facts, persistence, authorization, and invariant-bearing writes. Change the backend contract explicitly when the UI needs new domain data or behavior.
5. Consume backend routes through Rails-provided path props or generated helpers from `@/utils/routes`. Do not rebuild Rails route semantics in components or hand-edit generated files under `app/frontend/api`.

   **Repository convention:** Use a path prop directly when Rails provides it. Otherwise use a generated helper:

   ```tsx
   const purchasePath = purchase.path;
   const sizePath = routes.sizes.show.path({ id: size.id });
   ```

6. Keep components readable from public contract to feature composition to private mechanics. Use domain language and name non-obvious decisions or derived values when that makes ownership clear.
7. Apply the conditional references, then validate with the repository-wide gate in `AGENTS.md`.

## Refactor Safety

- Structural refactors must also preserve frontend-only behavior: accessibility, focus, scroll position, request and invalidation timing, and stale-state visibility.
- Keep one writer and named commands for behavior-bearing state. Use effects for synchronization, not as a hidden second write path.
- Prefer the simplest inspectable state representation. Do not add global state, Context, reducers, adapters, or compatibility layers without a distinct owner and responsibility.
- Do not extract for file length or hypothetical reuse. A component variant is valid when variants share one owner, contract, and lifecycle; split them when those meanings diverge.
- Use props for values that vary by instance and a provider for behavior genuinely shared by a subtree. Choose based on ownership and lifetime, not a fixed component-depth rule.
