---
name: inline-cell-editor
description: Add or change a persisted inline table-cell editor in this Rails, Inertia, and React app. Use when a table cell displays a backend value and edits it in place, including its Rails write resource, authorization, generated route contract, shared React form shell, field-specific behavior, sibling coordination, and test seams. Use alongside `collaborative-planning`, `rails-domain-architecture`, and `frontend-architecture`.
---

# Inline Cell Editor

## Usage

- Use `collaborative-planning` to run the process. Load this skill with both `rails-domain-architecture` and `frontend-architecture` before gathering detailed evidence, and keep all applicable skills active through implementation and validation.
- Complete the Rails Domain Contract and Frontend Contract when their behavior or boundary gates apply. Incorporate conditional `architecture-review.md` decisions through those contracts instead of adding another checklist here.
- Read the frontend [testing reference](../frontend-architecture/references/testing.md) when choosing or implementing test seams.
- Treat this skill as the low-freedom workflow for inline cells, not as a replacement for the owning Rails and frontend architecture rules.

Current seams to inspect before changing the pattern:

- The inline-cell write resources under `app/controllers/purchase_items/`: `PurchaseItems::TrackingNumbersController`, `PurchaseItems::ShippingCompaniesController`, `PurchaseItems::ShippingCostsController`, and `PurchaseItems::ShippingDetailsController`. The top-level `ShippingCompaniesController` is a different resource, and `PurchaseItems::SaleItemLinksController` is not an inline cell editor.
- `@/components/inline-cell-editing`
- `@/components/purchase-item-cells`
- `app/frontend/pages/Purchases/Show/PurchaseItems/useInlineEditorCascade.ts`
- `spec/requests/purchase_item_inline_updates_spec.rb` and the focused Cuprite feature specs

## Contract

- Default one independently saved field to one singular nested write resource, one explicit policy capability, and one field editor.
- Use one atomic multi-field command only when one user action or invariant requires the values to succeed or fail together. `shipping_details` is the current example.
- Keep controllers responsible for parameters, authorization, request loading, redirect targets, and Inertia errors. Route domain validation and invariant-bearing writes through the backend owner.
- Allow a direct owner-model update only when the simple attribute update is the public write API and model or database enforcement keeps every invariant intact.
- Keep backend values authoritative. React may perform a convenience check before submit, but it must not become another source of domain truth.
- Keep `return_to` in the request contract; default it from `usePage().url` so the editor returns to the current page.
- Keep generated helpers from `@/utils/routes` as the route contract. Do not pass new per-field update paths in page props or hand-edit files under `app/frontend/api`.
- Expose the displayed value and any required label or denormalized field in page props and TypeScript types.

## Implementation Path

1. Inspect the existing route, controller family, policy capability, owner model, props, editor, coordination behavior, and tests before placing the change.
2. Add a singular nested write resource for an independently saved field. Regenerate JsFromRoutes artifacts through the repository mechanism after route changes.
3. Start the request from the authorized relation named by the Rails Domain Contract and call the backend owner. Do not assume a controller concern creates that boundary.
   - Existing `PurchaseItemScoped` only shares `PurchaseItem.with_media.find` loading. It is not an authorized or access-scoped relation.
   - If the task needs to change that request boundary, return it as a material application decision instead of silently rewriting or misdescribing it.
4. Give the endpoint an explicit policy capability. Permit only the intended field or atomic field group, redirect on both success and failure, and expose validation errors through the existing Inertia error flow.
5. Compose the React editor from `InlineCellEditor` and `useInlineCellForm` in `@/components/inline-cell-editing`.
6. Pass the hook its explicit resource contract: `editedRecord`, `attributeName`, generated `route`, `collection`, `paramKey`, and `idParam`. Reuse `purchaseItemResource` for the shared PurchaseItem values.
7. Use `mapNewValueToState` for optimistic type conversion or denormalized display fields, `normalizeValueForSave` for submission normalization, `errorFrom` for cross-field errors, and `onOpen` only for a real open transition side effect.

## Frontend Ownership

- Let `useInlineCellForm` own generic open and close state, Inertia form state, payload transformation, optimistic collection replacement, error reopening, and saved feedback.
- Let `InlineCellEditor` own the stable table cell, accessible display and edit shells, Save and Exit controls, and its imperative handle.
- Let each field editor own its control, formatting, normalization, field-specific convenience checks, and error wording.
- Let the page or page-owned hook own sibling coordination and atomic bulk submission. Do not teach the shared hook domain nouns or page-specific cascade rules.
- Use imperative refs only when sibling editors genuinely coordinate. Use `openSilently` through the shared handle so an automatic open does not trigger another cascade.
- Keep single-field endpoints available when fields are independently editable. Add a grouped endpoint only for the approved atomic interaction; do not create a second general write path for the same behavior.

## Tests and Verification

- Add request coverage for the exact path, permitted payload, authorization, redirect, persistence, validation errors, and atomic rollback when fields save together.
- Add component coverage for accessible open and edit controls, payload and route use, local checks, normalization, optimistic state, success, and error reactions.
- Use `nextFormErrors` to test the component response after form errors are delivered. Use Cuprite when proving the real Rails and Inertia redirect lifecycle, focus or keyboard behavior, row-event handling, or multi-editor coordination.
- Test the owner model separately when validation, callbacks, derived values, or another domain invariant changes.
- Run the repository-wide verification gate in `AGENTS.md`; do not replace it with a skill-specific command list.
