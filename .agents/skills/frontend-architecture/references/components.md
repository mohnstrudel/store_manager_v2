# Frontend Component Structure

Read this reference when adding a component or structurally refactoring a component or page. Use the Frontend Contract to settle ownership and state before choosing a file shape.

## File Order

**Repository convention:** Keep a component file readable from its public contract to its private mechanics. The bodies below are placeholders; the order is the convention:

```tsx
type ProductFormProps = { product: ProductRecord };

export default function ProductForm(props: ProductFormProps) {
  return (
    <>
      <IdentityFields product={props.product} />
      <DetailsFields product={props.product} />
    </>
  );
}

function IdentityFields({ product }: { product: ProductRecord }) {
  // Section markup
}

function DetailsFields({ product }: { product: ProductRecord }) {
  // Section markup
}

function useProductFormState() {
  // Distinct owned behavior
}

function shouldShowPurchase() {
  // Named decision
}
```

Put imports first, followed by public props and shared types, the exported component, private sections in render order, owned hooks, and small helpers. Keep a private part in the same file while the file remains readable and the part does not own an independent subsystem.

## Page-Local Placement

**Illustration:** A page and its owned sections can grow like this:

```text
pages/Products/Show.tsx
pages/Products/Show/
  Header.tsx
  Gallery.tsx
  Details/
    Details.tsx
    PriceSection.tsx
    InventorySection.tsx
```

Names will vary. Keep the ownership rule: page-owned UI stays near its page until proven reuse, an independent subsystem, or a stable shared primitive creates a better boundary.
