---
name: inline-cell-editor
description: Add or change an inline table-cell editor in this Rails + Inertia + React app. Covers the local backend resource pattern, js-from-routes contract, shared React shell/hook, sibling editor coordination, and verification.
---

# Inline Cell Editor

Use this skill when a table cell displays a persisted value and turns into a small edit form in place. In this app, inline editors are write resources: one edited attribute gets one nested route, one small controller, one policy method, and one React editor composed from the shared shell and hook.

Current examples:

- `PurchaseItems::TrackingNumbersController`
- `PurchaseItems::ShippingCompaniesController`
- `PurchaseItems::ShippingCostsController`
- `app/frontend/lib/useInlineCellForm.ts`
- `app/frontend/components/InlineCellEditor.tsx`
- `app/frontend/pages/Warehouses/Show/InlineTrackingNumberEditor.tsx`
- `app/frontend/pages/Purchases/Show/InlineShippingCostEditor.tsx`

## Golden Path

### 1. Add a singular nested route

Use a singular `resource` under the owning collection. Do not add broad member actions to `PurchaseItemsController`.

```ruby
# config/routes.rb
resources :purchase_items, except: %i[new create] do
  scope module: :purchase_items do
    resource :tracking_number, only: :update
    resource :shipping_company, only: :update
    resource :shipping_cost, only: :update
    resource :your_field, only: :update
  end
end
```

This generates a route like:

```text
PATCH /purchase_items/:purchase_item_id/your_field
```

After changing routes, regenerate the JsFromRoutes files under `app/frontend/api`. They are generated files; do not hand-edit them. The React editor should import the generated helper through `@/lib/routes`.

### 2. Add one controller for the field

Keep the controller boring: load the purchase item, update exactly one attribute, redirect back, and pass validation errors through Inertia.

```ruby
# app/controllers/purchase_items/your_fields_controller.rb
# frozen_string_literal: true

module PurchaseItems
  class YourFieldsController < ApplicationController
    include PurchaseItemScoped

    def update
      if @purchase_item.update(your_field: params[:purchase_item][:your_field])
        redirect_to return_path, notice: "Your field was successfully updated"
      else
        redirect_to return_path, inertia: inertia_errors(@purchase_item.errors)
      end
    end

    private

    # Match the current Authorization concern spelling.
    def authorize_resourse
      authorize :purchase_item, :update_your_field?
    end

    def return_path
      params[:return_to].presence || purchase_item_path(@purchase_item)
    end
  end
end
```

Local details that matter:

- `PurchaseItemScoped` loads `@purchase_item` from `params[:purchase_item_id]` with `PurchaseItem.with_media`.
- `ApplicationController#inertia_errors` returns `{ errors: ... }` for Inertia redirect props.
- The app's authorization concern currently calls `authorize_resourse`; use that spelling in overrides unless the concern itself is refactored in the same change.
- Controllers redirect; they do not render partials, JSON, or inline-specific responses.

### 3. Add a granular policy method

```ruby
# app/policies/purchase_item_policy.rb
def update_your_field?
  admin?
end
```

Prefer one policy method per editable attribute. It keeps field-level unlocks explicit and avoids hiding permissions in a generic `update?`.

### 4. Put domain rules on the model

The controller should only assign the requested attribute. Validations, callbacks, derived totals, and cross-field requirements belong on the owning model or a model concern.

Use `app/models/purchase_item/<capability>.rb` when the behavior is a coherent PurchaseItem capability. Example: shipping cost affects purchase totals through `PurchaseItem::Shipping`.

For simple validations, it is fine to keep the rule directly in `app/models/purchase_item.rb`, as the tracking-number requirement currently does:

```ruby
validates :shipping_company_id,
  presence: true,
  if: -> { tracking_number.present? }
```

Do not duplicate backend validation rules in React. The frontend may do pre-submit convenience checks only when they improve the editing flow.

### 5. Add the value to page props and TypeScript types

Expose the displayed value and any denormalized display fields already needed by the table row. Do not add per-field update path props for new editors; the frontend gets update paths from JsFromRoutes.

Purchase page records live in:

- `app/helpers/purchase_helper.rb`
- `app/frontend/pages/Purchases/types.ts`

Warehouse page records live in:

- `app/helpers/warehouse_helper.rb`
- `app/frontend/pages/Warehouses/types.ts`

Keep prop names aligned with the persisted attribute where possible:

```typescript
export type PurchaseItemRecord = {
  id: number;
  your_field: string;
};
```

For selects or denormalized display, include both the id and label:

```typescript
shipping_company_id: number | null;
shipping_company_name: string;
```

## React Editor Pattern

### Use the shared shell and hook

Every inline editor should compose:

- `InlineCellTd`, `InlineCellTrigger`, and `InlineCellForm` from `@/components/InlineCellEditor`.
- `useInlineCellForm` from `@/lib/useInlineCellForm`.
- A generated route helper from `@/lib/routes`.

The hook owns open/closed state, Inertia form state, default `return_to`, payload shape, optimistic row replacement, error reopening, and saved highlighting. Do not reimplement that in the editor.

```tsx
import { forwardRef, useImperativeHandle } from "react";
import FormError from "@/components/FormError";
import { InlineCellForm, InlineCellTd, InlineCellTrigger } from "@/components/InlineCellEditor";
import { useInlineCellForm } from "@/lib/useInlineCellForm";
import routes from "@/lib/routes";
import type { PurchaseItemRecord } from "../types";

type YourFieldEditorProps = {
  item: PurchaseItemRecord;
  onAutoOpen?: () => void;
};

export const InlineYourFieldEditor = forwardRef<
  { open(): void },
  YourFieldEditorProps
>(function InlineYourFieldEditor({ item, onAutoOpen }, ref) {
  const { isOpen, isSaved, open, close, openSilently, error, onChange, save, value } =
    useInlineCellForm({
      editedRecord: item,
      attributeName: "your_field",
      route: routes.purchaseItemsYourFields.update,
      onOpen: onAutoOpen,
    });

  useImperativeHandle(ref, () => ({ open: openSilently }));

  return (
    <InlineCellTd className="text-center min-w-32" isSaved={isSaved} onOpen={isOpen ? undefined : open}>
      {isOpen ? (
        <InlineCellForm onCancel={close} onSave={save}>
          <label className="sr-only" htmlFor={`purchase_item_${item.id}_your_field`}>
            Your field
          </label>
          <input
            autoFocus
            className="border rounded px-2 py-1 text-sm w-full"
            id={`purchase_item_${item.id}_your_field`}
            onChange={onChange}
            type="text"
            value={value}
          />
          <FormError>{error}</FormError>
        </InlineCellForm>
      ) : (
        <InlineCellTrigger ariaLabel="Edit your field" onOpen={open}>
          {item.your_field ? <span>{item.your_field}</span> : null}
        </InlineCellTrigger>
      )}
    </InlineCellTd>
  );
});
```

### Hook conventions

`useInlineCellForm` expects:

- `editedRecord`: the row record. It must have `id`.
- `attributeName`: the exact backend attribute being patched.
- `route`: a generated JsFromRoutes PATCH helper such as `routes.purchaseItemsTrackingNumbers.update`.
- `mapNewValueToState`: optional optimistic state mapper.
- `returnTo`: optional; defaults to `usePage().url`.
- `errorFrom`: optional custom server-error reader.
- `onOpen`: optional side effect when the user opens the editor.

The hook derives:

- `updatePath` from `route.path({ [idParamName]: editedRecord.id })`.
- strong-param key from the route, usually `purchase_item`.
- page collection from the route, usually `purchase_items`.
- payload shape: `{ purchase_item: { your_field: value }, return_to }`.
- Inertia options: optimistic update, `preserveScroll`, close before request, reopen on error, mark saved on success.

### Use `mapNewValueToState` for type coercion or denormalized fields

Inputs and selects emit strings. If the row stores a number, `null`, formatted money, or a display label, map it explicitly for the optimistic row update.

```tsx
mapNewValueToState: (shippingCompanyId) => ({
  shipping_company_id: shippingCompanyId ? Number(shippingCompanyId) : null,
  shipping_company_name: shippingCompanyName(shippingCompanies, shippingCompanyId),
}),
```

### Use `errorFrom` only for cross-field errors

The default error reader is enough for normal fields:

```text
errors[attributeName] || errors.base || "Could not save <label>"
```

Pass `errorFrom` when the model reports another field's error for this save. Tracking number does this because saving a tracking number without a shipping company produces a `shipping_company_id` error.

```tsx
function trackingNumberError(errors: Record<string, string>) {
  if (Object.keys(errors).length === 0) return "";

  return (
    errors.tracking_number ||
    errors.shipping_company_id ||
    errors.base ||
    "Could not save tracking number"
  );
}
```

### Keep pre-submit UX checks local

Small client-side guards are allowed when they prevent a confusing round trip, but they must stay in the editor, not in the shared hook. Tracking number is the model example: if no shipping company exists, show a local error and do not submit.

```tsx
const saveTrackingNumber = useCallback(() => {
  if (requiresShippingCompany) {
    setShippingError("Shipping company is required");
    return;
  }
  save();
}, [requiresShippingCompany, save]);
```

### Coordinate sibling editors through refs when needed

If opening one editor should open another, expose `openSilently` through a ref. Use `openSilently` for sibling auto-open so the second editor does not trigger its own `onOpen` side effect and create a cascade.

```tsx
const shippingRef = useRef<{ open(): void }>(null);

const trackingAutoOpenShipping = useCallback(() => {
  shippingRef.current?.open();
}, []);
```

Then pass the callback to the editor that initiates the coordination:

```tsx
<InlineTrackingNumberEditor
  item={item}
  onAutoOpenShipping={trackingAutoOpenShipping}
/>
<InlineShippingCompanyEditor
  ref={shippingRef}
  item={item}
  shippingCompanies={shippingCompanies}
/>
```

## Tests

### Request specs

Add or update `spec/requests/purchase_item_inline_updates_spec.rb`.

Cover:

- successful update redirects to `return_to`;
- persisted attribute changes;
- validation failure redirects and exposes Inertia errors on follow-up render;
- type-sensitive fields, such as decimal shipping cost, persist the right type.

```ruby
patch purchase_item_your_field_path(purchase_item), params: {
  purchase_item: {your_field: "new value"},
  return_to: warehouse_path(warehouse)
}

expect(response).to redirect_to(warehouse_path(warehouse))
expect(purchase_item.reload.your_field).to eq("new value")
```

### Component tests

Add focused coverage to the page/component test where the editor appears, usually `app/frontend/pages/Warehouses/Show.test.tsx` or `app/frontend/pages/Purchases/Show.test.tsx`.

Cover the behavior users and Inertia care about:

- open by accessible button name, e.g. `screen.getByRole("button", { name: "Edit your field" })`;
- edit by accessible label;
- PATCH path and payload;
- `return_to` defaults to the current page URL;
- `preserveScroll: true`;
- optimistic close and saved highlight;
- server errors reopen/stay inside the inline editor;
- local pre-submit checks do not call `patch`;
- sibling auto-open behavior, if present.

Avoid snapshot-heavy tests. Inline editors are interaction contracts, not static markup.

## Invariants

- One inline field equals one singular nested route, one small controller, and one granular policy method.
- Controllers update exactly the intended attribute and redirect every time.
- Use `return_to`; default frontend return path is `usePage().url`.
- Use generated route helpers from `@/lib/routes`; do not pass update paths as page props for new editors.
- Use `InlineCellTd` as the stable `<td>` wrapper so display and edit states do not flicker or break row navigation.
- Use `InlineCellTrigger` and `InlineCellForm` with children. Do not pass JSX or inline render functions as props.
- Keep domain validation and side effects in `PurchaseItem` or `app/models/purchase_item/*`.
- Keep client-only pre-submit checks local to the specific editor.
- Use `mapNewValueToState` for optimistic type conversion and denormalized row fields.
- Use `openSilently` for sibling editor coordination.

## Practical Limits

- Do not create another per-resource wrapper around `useInlineCellForm` unless the call sites become noisy again. The hook now derives the route, param, collection, update path, return path, open state, and saved state; wrappers are only worth it when they remove real repeated decisions.
- Do not put backend route/path knowledge into helpers just for inline editors. JsFromRoutes is the frontend route contract.
- Do not make the shared hook understand field-specific business rules. Once a rule mentions shipping company, tracking number, money formatting, or another domain noun, it belongs in the editor or backend model.

## Verification

Before calling inline-editor work done:

```bash
mise exec -- bundle exec rubocop <changed Ruby files/specs>
pnpm lint
pnpm lint:perf
pnpm test:run <changed frontend test files>
mise exec -- bundle exec rspec spec/requests/purchase_item_inline_updates_spec.rb
```

Also run any directly affected model or policy specs when domain rules or authorization change, for example:

```bash
mise exec -- bundle exec rspec spec/models/purchase_item_shipping_spec.rb spec/policies/purchase_item_policy_spec.rb
```
