# Frontend Testing

Read this reference when adding or changing frontend tests, or when choosing a test strategy is part of the design. Routine verification of a mechanical change does not require it. Use the Frontend Contract to decide what behavior and invariant needs proof; use this reference to choose the local test seam.

## Choose the Seam

- Use a component test by default for rendering, conditional UI, local state transitions, validation messages, loading, empty, error, and user interaction.
- Use a Cuprite feature spec when correctness depends on the real browser or Rails/Inertia round trip: focus, keyboard behavior, layout, scrolling, file APIs, drag and drop, several components coordinating in one DOM, or redirect-with-errors behavior.
- Ask whether a component test could pass while the real behavior is broken. If yes, cover that risk with one focused browser scenario rather than retesting the whole screen.
- Add a matching Rails test when the backend contract, authorization, persistence, or domain command changes. A backend request spec does not replace user-visible frontend coverage.

## Inertia Errors

- Use `nextFormErrors` from `@/test/mocks/inertia` to test how a component reacts after its Inertia form receives errors: keep values, reopen an editor, display the message, or preserve local state.
- Do not treat that stub as proof of the real redirect-with-errors lifecycle. Use Cuprite when the risk is whether Rails, Inertia, and the component actually complete that round trip.
- Test client-side validation in a component test because no server or browser lifecycle is involved.

## Component Test Structure

- Colocate `Component.test.tsx` with `Component.tsx`.
- Give a child its own test when it owns branches, formatting decisions, interactions, or an empty state. Cover trivial markup through its public parent.
- Render real page-owned children when their coordination is part of the behavior under test. Mock a child only when the test targets the parent contract, the child is independently covered, and rendering it would add unrelated browser or integration cost.
- Never mock away the behavior owner or the contract being verified. Prefer real pure utilities and route helpers.
- Keep one user-visible behavior per test. Arrange, act, and assert in a readable order; extract a render helper only when it clarifies repeated setup.
- Name tests by observable behavior, not implementation mechanics.

## Factories and Mocks

- Use `app/frontend/test/factories.ts` for cross-domain factories and `pages/<Domain>/test/factories.ts` for domain records.
- Build a fully valid default record and accept typed `Partial<T>` overrides. Give list records distinct IDs.
- Inertia is replaced globally through `vitest.config.ts`. Do not add a per-file mock for `@inertiajs/react`.
- Import `mockPageProps`, `nextFormErrors`, and the shared router from `@/test/mocks/inertia` when tests need them.
- Mock at real boundaries such as browser APIs, Inertia, navigation adapters, API clients, or heavy browser-bound leaf components.
- Create browser API spies per test. The repository uses `mockReset: true`, so module-scope mock setup is not stable between tests.

**Repository convention:** A domain factory returns a valid default record and accepts scenario-specific overrides. Set IDs explicitly when building a list:

```tsx
export function makeSize(overrides: Partial<SizeRecord> = {}): SizeRecord {
  return {
    id: 1,
    value: "1:6",
    created_at: "19. May '26 16:18",
    updated_at: "19. May '26 16:18",
    ...overrides,
  };
}

const sizes = [makeSize({ id: 1 }), makeSize({ id: 2 })];
```

## Queries and Assertions

- Prefer accessible queries such as `getByRole` with a name. Use `within` when repeated controls need a clear section boundary.
- Assert the outcome a user can read or act on: text, enabled state, focus, navigation result, visible error, or rendered absence.
- Assert classes only when styling is itself the behavior and no clearer accessible or textual signal exists.
- Use `data-testid` only inside a deliberate test boundary or mock stub, not as the default query.
- Avoid snapshot-heavy tests and assertions on hook internals, setter calls, or callback counts when visible behavior can prove the same contract.

## Verification

Use the repository-wide verification gate in `AGENTS.md`. Do not replace it with a skill-specific command list.
