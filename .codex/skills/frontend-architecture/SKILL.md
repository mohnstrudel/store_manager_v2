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
