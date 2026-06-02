# Frontend Testing

Test the narrowest seam that still verifies user-visible behavior.

---

## Three layers, three blind spots

Every Inertia page is covered by three layers. Each is blind to the other two's bugs — none of the three replaces the others.

| Layer | Tool | Catches |
|---|---|---|
| Component test | Vitest + jsdom | Wrong rendering given props; React state; local interactions |
| Controller contract | RSpec request spec | Wrong prop keys/values from Rails; Pundit errors; HTTP status; `inertia_share` gaps |
| Browser integration | Cuprite | CSS geometry; file uploads; Stimulus controllers; real CRUD round-trips; native browser APIs |

Every new Inertia controller gets both a Vitest suite for its page component **and** a request spec for the controller contract. Cuprite is added only when a specific failure mode requires a real browser to surface.

---

## The diagnostic question

> **Can this failure be described without a real browser?**

- "The component renders the wrong text given these props" → Vitest
- "Rails sends the wrong prop key" → request spec
- "The CSS makes the element overflow on mobile" → Cuprite
- "After submit, the DB count is wrong" → Cuprite

If you need the Rails stack to detect the failure, use a request spec.  
If you need a rendered browser to detect the failure, use Cuprite.  
If you only need props and user events, use Vitest.

---

## Component tests (Vitest)

Use for rendering, conditional UI, validation error display, local state (adding/removing rows, dialog open/close, select cascades), empty and loading states.

Mock at the boundary: `usePage()`, `router`, navigation adapters, API clients. Do not spin up Rails.

```tsx
// Good — asserts what the user sees
pageErrors = { name: "can't be blank" };
rerender(<Form ... />);
expect(screen.getByText("can't be blank")).toBeInTheDocument();

// Bad — asserts internal wiring
expect(setErrors).toHaveBeenCalledWith({ name: "can't be blank" });
```

---

## Controller tests (RSpec request specs)

Use for HTTP status, `render_component("Resource/Page")`, prop shape, and authorization paths.

```ruby
get edit_purchase_path(purchase)
expect(inertia.props[:purchase]).to include(variant_id: variant.id)
```

---

## Browser tests (Cuprite)

Use only when the failure requires a real browser. If the test would trivially pass in jsdom even when the feature is broken, it belongs at a lower layer.

### Always requires Cuprite

**CSS geometry and layout** — `getBoundingClientRect()` always returns zeros in jsdom; `getComputedStyle` always returns empty strings. Any assertion about pixel dimensions, overflow, or computed color requires a real browser.

```ruby
expect(geometry["thumbImageHeight"]).to be_within(1.0).of(geometry["thumbFrameHeight"])
expect(page.evaluate_script("getComputedStyle(el).borderTopColor")).to match(/185, 28, 28/)
```

**File uploads** — Real binary content, object URLs, upload previews, and the ActiveStorage backend require a browser talking to a real server.

```ruby
find("[data-testid='new-images-input']", visible: false).set(paths)
expect(page).to have_css("[data-testid='image-pending-badge']", count: 3, wait: 15)
```

**Stimulus controllers** — Stimulus is wired to the real DOM at runtime. `window.Stimulus.getControllerForElementAndIdentifier(...)` does not exist in jsdom.

**Real CRUD round-trips** — When the assertion is about DB state after a full React → Rails → DB cycle. Vitest tests the React half; request specs test the Rails half; Cuprite tests both assembled, including "was the form posted to the right endpoint, and did the right records get created."

```ruby
expect {
  click_button "Create Purchase"
}.to change(Purchase, :count).by(1)
  .and change(PurchaseItem, :count).by(5)
```

**Native browser APIs** — `scrollIntoView`, `IntersectionObserver`, native `<dialog>` open/close, mobile viewport overflow, keyboard focus management, drag and drop.

### Does not need Cuprite

If the behavior is already covered by Vitest + request spec, a Cuprite spec is duplication that adds CI cost without adding signal. Before writing a browser test, check:

1. Is the rendering (given the right props) already tested in Vitest? → Cuprite's visual assertion adds nothing.
2. Is the prop contract already verified in a request spec? → Cuprite's "it appears on the page" assertion adds nothing.
3. Is the interaction entirely within one React component? → Vitest `userEvent` is sufficient.

**Common duplication traps**

- **Button/link presence** — if the Vitest Index test already asserts the link exists with the correct href, a Cuprite spec that visits and checks the same link is a duplicate.
- **Dialog open/close** — if `SyncModal.test.tsx` tests open/close via `userEvent`, a Cuprite spec doing the same is a duplicate.
- **Select initial value from props** — if the request spec verifies `variant_id` is in props and the component test verifies the select renders with that value, a Cuprite spec checking the select label is a duplicate.
- **Validation error banner** — if Vitest renders the page with an errors prop and asserts "Fix errors and try again", a Cuprite spec that submits blank and checks the banner is a duplicate. The `Sale.count` assertion belongs in the request spec.

---

## What goes wrong

**Cuprite as the default** — writing browser tests for every new page because they "test everything." This hides where the actual bug lives and makes the suite slow.

**Vitest without request specs** — a Vitest test proves the component renders correctly given props; a request spec proves Rails sends the right props. One without the other leaves a gap.

**Duplicating at a higher layer** — writing a Cuprite test that re-asserts what Vitest + request spec already cover. The duplicate adds cost but no signal.

**Testing implementation instead of behavior** — asserting `setState`, hook internals, or mock call counts when a visible outcome (`screen.getByText`, `toHaveAttribute`) is available.

---

## Rule of thumb

Use the smallest test that can detect the failure.

- Use **Vitest** when the failure is in how the component renders or behaves given its props.
- Use a **request spec** when the failure is in what Rails sends to the component.
- Use **Cuprite** only when the failure requires a real browser — CSS layout, file I/O, Stimulus, native APIs, or the full assembled round-trip.
