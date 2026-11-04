---
name: inline-cell-editor
description: Add or change a persisted inline table-cell editor in this Rails, Inertia, and React app. Use when a table cell displays a backend value and edits it in place, including its Rails write resource, authorization, generated route contract, shared React form shell, field-specific behavior, sibling coordination, and test seams. Use alongside `collaborative-planning`, `rails-domain-architecture`, and `frontend-architecture`.
---

# Inline Cell Editor

## Usage

- Load this skill with both `rails-domain-architecture` and `frontend-architecture`; complete their Domain Contract and Frontend Contract when their gates apply. Load `rails-testing` for the request boundary.
- Find the current editors with `grep -rl 'useInlineCellForm(' app/frontend` and the write resources in `app/controllers/purchase_items/`; read `spec/requests/purchase_item_inline_updates_spec.rb` and the focused Cuprite specs before changing the pattern.
- `PurchaseItemScoped` only shares `PurchaseItem.with_media.find` loading. It is not an authorized or access-scoped relation; changing that boundary is a material decision to return, not a silent rewrite.

## Contract

- Default one independently saved field to one singular nested write resource, one explicit policy capability, and one field editor.
- Use one atomic multi-field command only when one user action or invariant requires the values to succeed or fail together. `shipping_details` is the current example.
- Keep controllers responsible for parameters, authorization, request loading, redirect targets, and Inertia errors. Route domain validation and invariant-bearing writes through the backend owner.
- Allow a direct owner-model update only when the simple attribute update is the public write API and model or database enforcement keeps every invariant intact.
- Keep backend values authoritative. React may perform a convenience check before submit, but it must not become another source of domain truth.
- Keep `return_to` in the request contract; default it from `usePage().url` so the editor returns to the current page. The controller includes `ReturnPath` and defines `default_return_path`; `return_path` honors only a same-host `return_to`.
- Keep generated helpers from `@/utils/routes` as the route contract. Do not pass new per-field update paths in page props or hand-edit files under `app/frontend/api`.
- Expose the displayed value and any required label or denormalized field in page props and TypeScript types.

## Implementation Path

1. Add a singular nested write resource for an independently saved field and regenerate the JsFromRoutes artifacts.
2. Start the request from the authorized relation named by the Domain Contract and call the backend owner. Give the endpoint an explicit policy capability, permit only the intended field or atomic group, redirect on success and failure, and expose validation errors through the existing Inertia error flow.
3. Compose the editor from `InlineCellEditor` and `useInlineCellForm` in `@/components/inline-cell-editing`. Pass the hook its typed resource contract; reuse `purchaseItemResource` for PurchaseItem fields. Use its optional transforms (`mapNewValueToState`, `normalizeValueForSave`, `errorFrom`, `onOpen`) only for the behavior they name.

## Frontend Ownership

- `useInlineCellForm` owns generic open and close state, Inertia form state, payload transformation, optimistic collection replacement, error reopening, and saved feedback.
- `InlineCellEditor` owns the stable table cell, accessible display and edit shells, Save and Exit controls, and its imperative handle.
- Each field editor owns its control, formatting, normalization, field-specific convenience checks, and error wording.
- The page or a page-owned hook owns sibling coordination and atomic bulk submission. Do not teach the shared hook domain nouns or page-specific cascade rules.
- Use imperative refs only when sibling editors coordinate; `openSilently` through the shared handle opens without triggering another cascade.
- Keep single-field endpoints when fields are independently editable. Add a grouped endpoint only for the approved atomic interaction, never as a second general write path.

## Tests

- Request coverage: exact path, permitted payload, authorization, redirect, persistence, validation errors, and atomic rollback when fields save together.
- Component coverage: accessible open and edit controls, payload and route use, local checks, normalization, optimistic state, success, and error reactions; `nextFormErrors` drives the error case.
- Cuprite: the real Rails and Inertia redirect lifecycle, focus or keyboard behavior, row events, or multi-editor coordination.
- Owner model: validation, callbacks, derived values, or another domain invariant.
