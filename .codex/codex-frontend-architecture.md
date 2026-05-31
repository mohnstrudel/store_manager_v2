# Frontend Architecture

Components should describe feature behavior, not implementation details.

- Prefer intention-revealing code.
- Extract behaviors into custom hooks when logic represents a distinct behavior, lifecycle, synchronization process, or external integration.
- Use domain language for business concepts and user actions.
- Separate decisions from execution by extracting complex conditions into named predicates.
- Push complexity down into hooks, utilities, and child components.
- Keep state minimal; derive values whenever possible.
- Keep page components small and focused on composition.
- Organize page-owned UI by screen sections.
- Keep one-screen-only components close to the page that owns them.
- Move components to shared folders only when reuse is real.
- The top level of a component should read like a feature description.
- A reader should understand the feature before understanding the implementation.

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

Prefer:

```tsx
useRestoreDraft();
useTrackProductView();
useSyncFiltersWithUrl();
```

Over:

```tsx
useEffect(...);
useEffect(...);
useEffect(...);
```

Prefer:

```tsx
if (shouldRestoreDraft(user)) {
  restoreDraft();
}
```

Over:

```tsx
if (
  user &&
  user.settings &&
  !user.settings.disabled &&
  localStorage.getItem(...)
) {
  ...
}
```

Prefer:

```tsx
applyCoupon();
submitOrder();
restoreDraft();
```

Over:

```tsx
processData();
handleResponse();
updateState();
```

Prefer:

```tsx
const isSelected = selectedId === product.id;
```

Over:

```tsx
const [isSelected, setIsSelected] = useState(false);
```

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

Over placing helper components or utilities above the main component unless they are required to understand the public API.

## Screen Organization

Prefer screen-first organization.

Keep page-owned UI close to the page.

```text
pages/products/Show.tsx
pages/products/Show/
  Header.tsx
  Gallery.tsx
  Details.tsx
  RelatedProducts.tsx
```

Expand into subfolders when a section becomes a small subsystem.

```text
pages/products/Show/
  Details/
    Details.tsx
    PriceSection.tsx
    InventorySection.tsx
```

Keep components page-local until reuse is real.

Prefer:

```text
pages/products/Show/Gallery.tsx
```

Over:

```text
components/Gallery.tsx
```

unless the component is genuinely shared across screens or resources.

## Avoid

- Large imperative `useEffect` blocks.
- Technical names such as `handleData`, `processResponse`, `updateState`.
- Mixing business rules with implementation details.
- Storing derived state.
- Deep abstraction layers without a clear behavioral boundary.
- Moving components to shared folders just because they were extracted.
- Tiny wrapper components that hide obvious JSX.
- Putting helper components or utilities above the main component when the file could read top-down.
- Splitting one screen across many distant files without a clear ownership boundary.
