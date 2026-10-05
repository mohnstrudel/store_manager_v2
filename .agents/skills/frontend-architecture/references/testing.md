# Frontend Testing

Read this reference when a frontend change needs a test-seam decision or uses the shared Inertia test harness. The Frontend Contract decides what behavior needs proof.

## Choose the Seam

- Use a component test for behavior fully observable through rendered React state and interaction.
- Use one focused Cuprite scenario when a component test could pass while real behavior is broken: browser APIs, focus or keyboard behavior, layout or scrolling, multi-component coordination, or the Rails/Inertia round trip.
- Add Rails request coverage when the backend contract, authorization, persistence, or domain command changes. Request coverage does not replace user-visible frontend coverage.

## Shared Inertia Harness

- `@inertiajs/react` is globally aliased to `@/test/mocks/inertia`; do not create per-file Inertia mocks. Use its shared page helpers, router, and `nextFormErrors`.
- `nextFormErrors` drives component error handling only. It does not prove redirect-with-errors across Rails, Inertia, and React.
- Vitest uses `mockReset: true`; configure shared mocks per test or in `beforeEach`, never at module or `describe` scope.
- The current form double drops optimistic callbacks and always reports `processing: false`. A component test using it cannot prove optimistic or processing-state behavior. Exercise the real lifecycle with Cuprite, or improve the canonical double once when the behavior is purely component-owned.
