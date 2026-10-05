# Frontend Styling

Read this reference when work changes CSS, layout, responsive or dark-mode behavior, visual state, or presentation markup.

## Style Ownership

- Use Tailwind as a styling primitive, not as the only language visible in JSX.
- Use semantic classes for a reusable UI concept or repeated visual pattern. Keep small, local adjustments as inline utilities.
- Do not extract a semantic class merely to rename one obvious utility. Extract when the name explains a stable concept or removes repeated visual decisions.
- Keep styles grouped by UI concept under `app/frontend/styles/application`. Keep third-party component styling isolated.
- Prefer UI or domain names over generic names such as `wrapper`, `inner`, or `box` when the surrounding block does not provide meaning.

## State and Accessibility

- Let the React owner decide state and let CSS own presentation. Do not make CSS a second source of behavior.
- Use `aria-*` when state has accessibility meaning, `data-*` for semantic styling hooks, and classes for reusable presentation. Combine them when each serves a distinct purpose.
- Do not require one universal state mechanism. Choose the representation that makes the contract inspectable and keeps accessibility accurate.
- Do not rely on color or a class alone when the user needs a textual, semantic, or interactive signal.
- Keep loading, disabled, selected, current, error, and stale presentation consistent with the state named in the Frontend Contract.

**Repository convention:** When CSS uses an attribute-presence selector, omit the attribute when the state is false:

```tsx
<div className="gallery_main__frame" data-loading={isLoading || undefined}>
```

```css
.gallery_main__frame[data-loading] {
  @apply animate-pulse;
}
```

`undefined` removes the attribute. Passing `false` to a `data-*` attribute can leave `data-loading="false"` in the DOM, which still matches `[data-loading]`. Add `aria-*` separately when the state has accessibility meaning.

## Layout and Variants

- Keep responsive and dark-mode behavior paired with the base style instead of adding them as a late exception.
- Use component props for variants that share one owner, public contract, accessibility behavior, and lifecycle. Use CSS scoping when the difference is presentation-only.
- Split a component when a variant changes meaning, interaction, state transitions, or accessibility rather than merely changing layout.
- Prefer existing design tokens and Tailwind scales. Use an arbitrary value only when the design has no suitable token and the value has a clear reason.

## Selector Boundaries

- Prefer named classes and shallow selectors over DOM-position selectors such as `> div`, `:first-child`, or deep descendant chains.
- Keep global element styles small and predictable.
- Avoid duplicated class definitions and repeated `@apply` groups.
- Verify that markup changes do not break focus, accessible names, responsive layout, dark mode, or state visibility.
