---
name: frontend-architecture
description: >-
  Use for React, browser-side UI, page composition, shared components, hooks,
  local state, frontend refactors, browser widgets, and frontend test strategy
  in this Rails app. Do not use for backend models, controllers, jobs,
  persistence rules, or domain workflows; use `rails-domain-architecture`
  instead.
---

# Frontend Architecture Skill

Use this skill for frontend design and refactoring work in `app/frontend`.

If the task needs new backend data, routes, route helpers, or persisted
behavior, coordinate that seam with `rails-domain-architecture`.

## Core Principle

Components should describe feature behavior, not implementation details.
The top level of a component should read like a feature description - a reader
should understand the feature before understanding the implementation.

- Prefer intention-revealing code.
- Extract behaviors into custom hooks when logic represents a distinct
  behavior, lifecycle, synchronization process, or external integration.
- Use domain language for business concepts and user actions.
- Separate decisions from execution by extracting complex conditions into named predicates.
- Push complexity down into hooks, utilities, and child components.
- Keep state minimal; derive values whenever possible.
- Keep page components small and focused on composition.

## Convention over Configuration

Prefer a design where the common case just works, and callers only supply what
genuinely varies. This reduces API surface and keeps call sites readable.

### Component API

Give optional props sensible defaults. Callers should not need to configure
behavior that should be conventional:

```tsx
// Prefer — callers pass only what varies
<ImageGallery media={product.media} />

// Avoid — caller forced to configure what should be a default
<ImageGallery media={product.media} layout="carousel" loadingStyle="pulse" />
```

A config prop that controls structural branching (`layout: "single" | "carousel"`)
is a sign the component is doing two things. Either make the convention work for
both cases (CSS scoping, data-attributes) or split into two components.

### CSS as convention

State-driven appearance belongs in CSS, not in JS config props or computed class
strings. Communicate state via `data-*` attributes and let CSS select on them:

```tsx
// Prefer — CSS owns the appearance, JS owns the state
<div className="gallery_main__frame" data-loading={isLoading || undefined}>

// Avoid — JS computes appearance from configuration
<div className={`gallery_main__frame ${isLoading ? "loading" : ""}`}>
```

Layout variation between modes (single vs. carousel) belongs in CSS scoping:

```css
/* convention: parent class scopes the variant */
.gallery_viewbox--single .gallery_main__image { @apply max-h-160 max-w-160; }
```

Rather than a `layout` prop that branches inline class strings inside the
component.

### Prop-drilling vs. context

When a behavior object would be threaded unchanged through three or more
component levels, use React Context instead. Context is the conventional
channel for shared subtree state; prop-drilling at that depth is
configuration leaking through seams that don't care about it.

Use props for per-item identity (`index`, `image`) — values that genuinely
differ per instance. Use context for shared behavior (`selectImage`,
`markLoaded`, `loaded`) — values that every consumer in the subtree needs.

## Default Workflow

1. Identify the boundary: page, shared component, custom hook, utility, or browser widget.
2. Read nearby files and follow existing local patterns.
3. Keep the top-level component intention-revealing: it should read like a feature description.
4. Extract distinct behaviors into custom hooks.
5. Use domain language for user actions and business concepts.
6. Separate decision-making from execution with named predicates.
7. Keep state minimal; derive values when possible.
8. Push implementation details into hooks, utilities, adapters, or child components.
9. Add or update tests at the right level: component test by default;
   browser-level test only when the risk lives in the browser itself.
10. Before calling the task done, run the full verification gate:
    ```bash
    npm run lint              # oxlint default rules
    npm run lint:perf         # react-perf rules
    npx tsc --noEmit          # type check
    npx vitest run app/frontend  # full component test suite
    ```
    All four must pass cleanly. Fix any failures before reporting done.

## Component Structure

Prefer:

```tsx
function ProductPage() {
  useTrackProductView(productId);
  useRestoreDraft();
  useSyncFiltersWithUrl(filters);

  return (
    <ProductLayout>
      <Header />
      <ProductDetails />
      <RelatedProducts />
    </ProductLayout>
  );
}
```

Over:

```tsx
function ProductPage() {
  useEffect(...);
  useEffect(...);
  useEffect(...);

  // hundreds of lines of logic and rendering
}
```

Prefer named hooks (`useRestoreDraft`, `useTrackProductView`) over raw `useEffect` blocks.

Prefer named predicates:

```tsx
if (shouldRestoreDraft(user)) {
  restoreDraft();
}
```

Over inline compound conditions.

Prefer named intermediate values over inline expressions in JSX. Any
non-obvious derivation should be named so the JSX reads as a feature
description, not a computation:

```tsx
// Prefer
const thumbnailIsLoading = !loaded.has(image.id);
const thumbnailIsActive = index === selectedIndex;

return (
  <div data-loading={thumbnailIsLoading || undefined}>
    <button data-active={thumbnailIsActive || undefined}>
```

Over:

```tsx
// Avoid
return (
  <div data-loading={!loaded.has(image.id) || undefined}>
    <button data-active={index === selectedIndex || undefined}>
```

The name describes *what it means*, not how it is computed. This applies equally
to conditions, derived flags, computed class names, and any other expression
where a reader would have to pause and evaluate instead of just reading.

The same principle applies to `useEffect`. Pass a named function so the call
site declares the purpose without requiring the reader to parse the body:

```tsx
// Prefer — intent is visible at the call site
useEffect(scrollSelectedThumbnailIntoView, [selectedIndex, thumbnailButtonRefs]);

function scrollSelectedThumbnailIntoView() {
  const selectedThumbnail = thumbnailButtonRefs.current[selectedIndex];
  if (!selectedThumbnail) return;
  // ...
}
```

Over:

```tsx
// Avoid — must read the body to understand why this effect exists
useEffect(() => {
  const selectedThumbnail = thumbnailButtonRefs.current[selectedIndex];
  if (!selectedThumbnail) return;
  // ...
}, [selectedIndex, thumbnailButtonRefs]);
```

Define the named function *after* the `useEffect` call. Function declarations
are hoisted, so this works — and it keeps the hook readable top-down: intent
first, implementation second.

Note: `|| undefined` is the conventional way to make a boolean React prop
omit the attribute entirely when false — CSS `[data-x]` selectors need absence,
not `data-x="false"`.

Prefer domain verbs (`applyCoupon`, `submitOrder`, `restoreDraft`) over
technical names (`processData`, `handleResponse`, `updateState`).

Prefer derived values:

```tsx
const isSelected = selectedId === product.id;
```

Over storing derived state in `useState`.

## Component File Hierarchy

When a component lives in one file, keep the file readable top-down:

1. Imports.
1. Public props and shared types needed to understand the component API.
1. The exported/main component.
1. Supporting section components in the order they render.
1. Custom hooks used by the main component.
1. Helper predicates, formatters, factories, and small utilities.

Prefer:

```tsx
type ProductFormProps = { ... };

export default function ProductForm(props: ProductFormProps) {
  return (
    <>
      <IdentityFields />
      <DetailsFields />
      <ImageGallery />
    </>
  );
}

function IdentityFields() {}
function DetailsFields() {}
function ImageGallery() {}

function useProductFormState() {}

function shouldShowPurchase() {}
function formatTitle() {}
```

Over placing helper components or utilities above the main component unless
they are required to understand the public API.

Private helper components, predicates, and formatters may stay in the same file
when they remain readable and page-owned. Split a section out when it has
multiple behaviors, shared ownership, or has become a named subsystem in the
screen.

## Screen Organization

Keep page-owned UI close to the page. Keep components page-local until reuse is real.

```text
pages/products/Show.tsx
pages/products/Show/
  Header.tsx
  Gallery.tsx
  Details.tsx
  RelatedProducts.tsx
```

Expand into subfolders when a section becomes a small subsystem:

```text
pages/products/Show/
  Details/
    Details.tsx
    PriceSection.tsx
    InventorySection.tsx
```

Prefer `pages/products/Show/Gallery.tsx` over `components/Gallery.tsx` unless
the component is genuinely shared across screens or resources.

## Testing

Choose the **narrowest seam that still verifies user-visible behavior**.

**Component tests are the default.** Use them for:

- Rendering, conditional UI, loading states, empty states
- Validation messages, button behavior, local state transitions
- User interactions

**Browser-level tests (Cuprite) only when the browser is the risk:**

- Dialogs, drag and drop, file uploads
- Keyboard navigation, focus management, scrolling
- Layout-sensitive behavior, multi-step workflows

Assert **outcomes**, not mechanics:

```tsx
// Good
expect(screen.getByText("Saved")).toBeVisible();
expect(button).toBeDisabled();

// Avoid
expect(mockSave).toHaveBeenCalledTimes(1);
expect(hookResult.current.isOpen).toBe(false);
```

Mock at the boundary only: Inertia, navigation adapters, API clients, backend
bridges. Do not recreate backend integration inside component tests.

**Server-error paths (`onError`) belong in Capybara, not component tests.**

When a component uses Inertia's `useForm` and its `onError` callback, the path
where the server returns validation errors requires a Cuprite spec. `onError`
fires through Inertia's redirect-with-errors cycle — a full Rails/HTTP/browser
round-trip. A component test can only simulate it with `nextFormErrors`, which
tests the stub's behavior, not the real Inertia flow. The stub can pass even if
the component never actually wires up `onError` correctly.

```ruby
# Do: Cuprite spec that submits to Rails and gets a real onError response
scenario "shows server errors without a full-page reload", :js do
  visit purchase_path(purchase)
  within(find_field("Tracking number").ancestor("form")) { click_button "Save" }
  expect(page).to have_text("Shipping company is required")
  expect(page).to have_current_path(purchase_path(purchase))  # stayed on page
end
```

```tsx
// Don't: component test simulating the onError round-trip via nextFormErrors
nextFormErrors.mockReturnValueOnce({ shipping_company_id: "can't be blank" });
await user.click(within(trackingForm).getByRole("button", { name: "Save" }));
expect(within(shippingForm).getByText("Shipping company is required")).toBeInTheDocument();
```

Client-side validation errors (checked before any request fires) are still fine
in component tests — they never reach the server and are pure UI logic.

When helper parts are extracted only to keep a file readable, tests should
usually target the public section behavior rather than each private helper.

If a frontend change also modifies a backend contract, add the matching backend test separately.

## Frontend / Backend Boundary

Frontend code may compose UI, local interaction state, browser behavior, and backend-provided props.

Do not move backend domain rules into React. If the UI needs new backend data
or behavior, update the backend contract explicitly instead of hiding that
need inside component code.

## Avoid

- Large imperative `useEffect` blocks.
- Components that read like execution plans instead of feature descriptions.
- Technical names like `handleData`, `processResponse`, or `updateState`.
- Mixing business rules with implementation details.
- Storing derived state.
- Deep abstraction layers without a clear behavioral boundary.
- Global state or abstraction layers before local composition is exhausted.
- Shared components for one-screen-only patterns without real reuse.
- Tiny wrapper components that hide obvious JSX.
- Putting helper components or utilities above the main component when the file could read top-down.
- Splitting one screen across many distant files without a clear ownership boundary.
- Backend contract changes hidden inside frontend code.
- Testing implementation details (hook internals, state variables, callback
  wiring) when visible outcomes can be asserted instead.
- Using browser tests for behavior already covered by a component test.
- Skipping browser tests when the browser itself is the risk.
- Letting backend request specs substitute for UI coverage.

## CSS Architecture

Use Tailwind as a styling primitive, not as the main UI language.

CSS classes should describe UI concepts and reusable visual patterns. JSX should stay readable without decoding long utility chains.

### Core Rules

- Prefer semantic class names over long Tailwind utility chains.
- Use `@apply` for repeated visual patterns.
- Use raw Tailwind utilities inline only for small, local, one-off adjustments.
- Keep styles grouped by UI concept: buttons, forms, tables, navigation, dialogs, gallery, rich text.
- Extract a class when the same utility combination appears more than once or represents a named UI concept.
- Do not extract a class only to rename one obvious utility.
- Prefer domain/UI names over generic names.
- Keep third-party component styling isolated.
- Keep global element styles minimal and predictable.
- Avoid deeply coupled selectors that depend on fragile DOM structure.

### Prefer

```html
<div class="gallery_main__frame">
  <img class="gallery_main__image" />
</div>
```

Over:

```html
<div class="flex items-center justify-center w-full h-full min-h-80 rounded-lg bg-gray-50 border">
  <img class="h-full w-full object-contain" />
</div>
```

### Prefer

```css
.gallery_main__frame {
  @apply flex items-center justify-center w-full h-full min-h-80 lg:min-h-full rounded-lg bg-gray-50 dark:bg-gray-800/40 border border-gray-100 dark:border-gray-800;
}
```

when the class represents a real UI concept.

### Use inline utilities for local variation

```tsx
<ProductCard className="mt-4" />
```

This is fine when the style is local and does not create a reusable pattern.

### Naming

Prefer:

```css
.gallery_thumb
.gallery_thumb__frame
.dialog_content
.pagination_link
.form_section_item
.empty_state
```

Over:

```css
.wrapper
.container
.inner
.box
.content
```

Generic names are acceptable only when the surrounding block gives them clear meaning.

### State Classes

Prefer explicit state names:

```css
.is_current
.is_selected
.is_loading
.is_active
.has_error
```

Over vague modifiers:

```css
.active
.selected
.loading
```

unless the selector is already scoped to a specific component.

### Avoid

- Long utility chains directly in JSX.
- Repeating the same `@apply` groups across multiple classes.
- Generic class names without UI meaning.
- Styling through fragile selectors like `> div`, `:first-child`, or deep descendant chains when a named class would be clearer.
- Duplicated class definitions.
- Arbitrary values when a Tailwind token is available.
- Large global base styles that make every element behave like a component.
