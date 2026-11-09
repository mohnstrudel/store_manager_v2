# Frontend Styling

Read this reference when work changes CSS, layout, responsive or dark-mode behavior, visual state, or presentation markup.

## Style Ownership

- Use Tailwind as a styling primitive, not as the only language visible in JSX.
- Use semantic classes for a reusable UI concept or repeated visual pattern. Keep small, local adjustments as inline utilities.
- Do not extract a semantic class only to rename one obvious utility. Extract when the name explains a stable concept or removes repeated visual decisions.
- Keep styles grouped by UI concept under `app/frontend/styles/application`. Keep third-party component styling isolated.
- Prefer UI or domain names over generic names such as `wrapper`, `inner`, or `box` when the surrounding block does not provide meaning.

## Sibling Consistency

- Before building UI, find the nearest existing sibling that shows the same concept or follows the same pattern: another modal, form, table, chip, or footer. Read its markup and CSS and measure its rendered spacing in the browser.
- Reuse the sibling's component or class. When two UIs need the same thing, extract one shared component or class instead of retyping class strings or recreating the look from memory.
- Use only spacing, gaps, widths, heights, and type sizes that the sibling already uses or that a global style defines, such as the label-to-control gap. A value that no sibling uses needs an explicit user decision. Never invent a size to make a layout feel right.
- Compare, do not assume: render the new UI next to its sibling in the same viewport and compare measured gaps (top, bottom, left, content-to-footer). Treat every difference as a defect until the user approves it.
- When the user asks for consistency or a mismatch has already been reported, pin it with a browser spec that measures the new UI against its sibling.
- Check UI defaults and data-driven states in the development environment as well as the test database; the test database can hide drift.

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
- Split a component when a variant changes meaning, interaction, state transitions, or accessibility rather than only changing layout.
- Prefer existing design tokens and Tailwind scales. Use an arbitrary value only when the design has no suitable token and the value has a clear reason.

## Selector Boundaries

- Prefer named classes and shallow selectors over DOM-position selectors such as `> div`, `:first-child`, or deep descendant chains.
- Keep global element styles small and predictable.
- Avoid duplicated class definitions and repeated `@apply` groups.
- Verify that markup changes do not break focus, accessible names, responsive layout, dark mode, or state visibility.

## Forms and Collections

- Group related form fields as bordered blocks inside a `section` with a heading, laid out in a grid. Never use tabs or accordions to separate form sections.
- An empty collection renders an empty state that says what the content is and how to add it, never a bare table head or list chrome. Reuse the existing empty-state card; use `SearchResultsEmpty` for search results.
- Keep visual change inside the task's scope: no new fonts, colors, or layout outside the UI the task touches. A redesign is its own task.
