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

## Concision and Boundaries

- Optimize for the reader's path: public contract, feature composition, then private mechanics. Prefer direct code when another name or layer does not clarify a decision.
- Keep small leaf renderers beside their owner when their names make composition easier to scan. Do not create one file per component mechanically.
- Do not create a hook, component, or helper that only renames another API, forwards props, or shortens JSX. Require an owned decision, lifecycle, protocol, or stable visual unit.
- Treat roughly 250–300 lines or more than seven private components, hooks, and helpers as a review signal, not a limit. Configuration, editorial data, and cohesive third-party adapters may legitimately remain longer.
- A file move is not an architectural improvement by itself. The new boundary must clarify ownership, dependencies, or the public contract.
- Write render-time values and handlers normally. Add `useMemo`, `useCallback`, or `memo` only for expensive work, a memoized child, a Hook dependency, or stable identity required by an external API. When lint requires stable props, prefer module-level constants or a simpler child contract before adding memoization scaffolding.
- Keep cohesive React presentation and its owned interaction state together. Move browser and external transport mechanics into an adapter when they form a separate protocol.

## Owner-Local Modules

Keep `<Owner>.tsx` as the public contract and composition file, and use `<Owner>/` as its private namespace. When the owner contains an independently meaningful capability—or crosses a complexity review signal and no longer scans coherently—move that capability's components, state Hook, types, helpers, and adapter together into `<Owner>/<Capability>.tsx` or `<Owner>/<Capability>/`. Export only the surface consumed by the owner.

- Keep trivial helpers in `<Owner>.tsx` when moving them would only add navigation.
- Name local modules for capabilities. Do not create generic `utils.ts`, `hooks.ts`, or `components.ts` buckets.
- Keep owner-local code private even when it has a useful test seam. Do not promote it into shared folders without proven reuse or a stable shared primitive.
- Allow the owner to import its local modules and allow those modules to import shared primitives. Do not let production code outside the owner import from `<Owner>/`; promote a deliberate public contract instead.
- Do not let one capability reach into another capability's private subfolder. Coordinate through the owner or extract a genuinely shared local contract.

**Illustration:** A page and its owned sections can grow like this:

```text
pages/Warehouses/components/Form.tsx
pages/Warehouses/components/Form/
  TransitionNotifications.tsx
```

Keep capability-owned pieces together under `<Owner>/`. Start with one `<Capability>.tsx` while the capability remains cohesive; introduce `<Owner>/<Capability>/` only when it contains multiple coherent modules with clear internal boundaries.
