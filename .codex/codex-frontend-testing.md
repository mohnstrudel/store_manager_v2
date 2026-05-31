# Frontend Testing

Test the narrowest seam that still verifies user-visible behavior.

## Core Rules

- Test behavior, not implementation details.
- Assert what the user can see, do, or observe.
- Prefer component tests by default.
- Use browser-level tests when the risk exists in the browser, not in the component.
- Mock data providers, navigation adapters, and backend bridges at the edge.
- If a frontend change also modifies backend contracts, add the matching backend test separately.

### Prefer

tsx expect(screen.getByText("Saved")).toBeVisible(); expect(button).toBeDisabled(); expect(dialog).not.toBeVisible();

Over:

tsx expect(setState).toHaveBeenCalled(); expect(hookResult.current.isOpen).toBe(false); expect(component.state.loading).toBe(true);

Test outcomes, not implementation mechanics.

---

### Prefer component tests

Most UI behavior should be verified with component tests.

Examples:

- Rendering
- Conditional UI
- Loading states
- Empty states
- Validation messages
- User interactions
- Button behavior
- Local state transitions

### Good

tsx await user.click(saveButton);  expect(screen.getByText("Saved")).toBeVisible();

### Avoid

tsx expect(mockSave).toHaveBeenCalledTimes(1);

unless the callback invocation itself is the behavior being tested.

---

### Use browser-level tests for browser risks

Use browser-level tests when correctness depends on actual browser behavior.

Examples:

- Dialogs
- Drag and drop
- File uploads
- Keyboard navigation
- Focus management
- Scrolling
- Layout-sensitive behavior
- Multi-step workflows
- Complex client-side interactions

### Good

text User uploads a file and sees a preview.

### Bad

text Verify upload callback was called.

when the visual upload flow is the real risk.

---

### Mock at the boundary

Mock:

- Inertia
- Navigation adapters
- API clients
- Backend bridges

Do not recreate backend integration inside component tests.

Keep component tests fast and deterministic.

---

## What Codex Often Gets Wrong

- Testing implementation details instead of user-visible behavior.
- Asserting hook internals, state variables, or callback wiring when visible outcomes can be asserted instead.
- Using browser tests for behavior already covered by a component test.
- Avoiding browser tests when the browser itself is the risk.
- Letting backend request specs substitute for UI coverage.
- Adding brittle screenshot-based assertions before writing focused behavior tests.

## Rule of Thumb

Choose the smallest test that can prove the behavior.

If a component test can prove it, use a component test.

If only a real browser can prove it, use a browser-level test.
