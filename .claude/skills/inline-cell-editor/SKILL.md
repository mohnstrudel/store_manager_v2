---
name: inline-cell-editor
description: >-
  How to add a new inline cell editor: a table cell that switches from display
  to an edit form on click, patches a single field, and returns via Inertia.
  Covers the full stack: route, controller, policy, model concern, helper,
  frontend component, and tests.
---

# Inline Cell Editor

An inline cell editor is a table cell that renders a value when idle and a
single-field form when active. Each editable field is its own sub-resource with
a dedicated route, controller, and policy method. This keeps domain rules in
the model, authorization explicit, and the frontend form stateless.

## Backend

### 1. Route — one sub-resource per field

```ruby
# config/routes.rb
resources :purchase_items, except: %i[new create] do
  scope module: :purchase_items do
    resource :tracking_number, only: :update   # PATCH /purchase_items/:id/tracking_number
    resource :shipping_company, only: :update  # PATCH /purchase_items/:id/shipping_company
    resource :your_field,       only: :update  # add new ones here
  end
end
```

The `resource` (singular) produces a single `update` route. No `index`, `show`, or
`new` actions are needed.

### 2. Controller — one per field

```ruby
# app/controllers/purchase_items/your_fields_controller.rb
module PurchaseItems
  class YourFieldsController < ApplicationController
    include PurchaseItemScoped   # sets @purchase_item via before_action

    def update
      if @purchase_item.update(your_field: params[:purchase_item][:your_field])
        redirect_to return_path, notice: "Your field was successfully updated"
      else
        redirect_to return_path, inertia: inertia_errors(@purchase_item.errors)
      end
    end

    private

    def authorize_resource
      authorize :purchase_item, :update_your_field?
    end

    def return_path
      params[:return_to].presence || purchase_item_path(@purchase_item)
    end
  end
end
```

- `PurchaseItemScoped` loads `@purchase_item` (see `app/controllers/concerns/purchase_item_scoped.rb`).
- `inertia_errors` converts ActiveModel errors for Inertia redirects (defined in `ApplicationController`).
- `return_to` lets the frontend control where to land after save.

### 3. Policy method

```ruby
# app/policies/purchase_item_policy.rb
def update_your_field?
  admin?
end
```

One method per field. Keep authorization at this granularity so fields can be
unlocked independently.

### 4. Model concern (when needed)

Create a concern when the field has cross-field validations, callbacks, or
derived state:

```ruby
# app/models/purchase_item/your_capability.rb
module PurchaseItem::YourCapability
  extend ActiveSupport::Concern

  included do
    validates :your_field, presence: true, if: -> { some_condition }
    after_save :update_derived_value, if: :saved_change_to_your_field?
  end

  private

  def update_derived_value
    # ...
  end
end
```

Include it in `PurchaseItem`:

```ruby
# app/models/purchase_item.rb
include YourCapability
```

For simple fields with no side-effects, skip the concern and put the validation
directly on the model.

### 5. Helper — expose the update path as a prop

```ruby
# app/helpers/warehouse_helper.rb  (or whichever helper builds the page props)
def warehouse_details_purchase_item_props(item)
  {
    # ... existing fields ...
    your_field_update_path: purchase_item_your_field_path(item),
  }
end
```

### 6. Request spec

```ruby
# spec/requests/purchase_item_inline_updates_spec.rb
describe "PATCH /purchase_items/:id/your_field" do
  it "updates the field and redirects" do
    patch purchase_item_your_field_path(item),
      params: { purchase_item: { your_field: "new value" }, return_to: "/warehouses/1" }
    expect(response).to redirect_to("/warehouses/1")
    expect(item.reload.your_field).to eq("new value")
  end

  it "redirects with errors on validation failure" do
    patch purchase_item_your_field_path(item),
      params: { purchase_item: { your_field: "" }, return_to: "/warehouses/1" }
    expect(response).to redirect_to("/warehouses/1")
    follow_redirect!
    # Inertia errors land in the session / shared props
  end
end
```

---

## Frontend

### 7. TypeScript type — add the update path

```typescript
// app/frontend/pages/Warehouses/types.ts
export type WarehousePurchaseItemRecord = {
  // ... existing fields ...
  your_field: string;
  your_field_update_path: string;
};
```

### 8. Component — `InlineYourFieldEditor.tsx`

Compose the two shared shell pieces and the shared hook:

- `InlineCellTrigger` / `InlineCellForm` (`@/components/InlineCellEditor`) — the
  generic, page-agnostic closed/open shell. The trigger is a click-to-edit cell
  with hover highlight; the form wraps your field(s) with Save / Exit. Both take
  their content as **children** (never pass JSX or inline functions as props —
  `react-perf` lint rules forbid it).
- `useInlineCellForm` (`@/lib/useInlineCellForm`) — owns the Inertia form value,
  syncs back to the persisted value while closed, and runs the optimistic patch.
  It **bakes in the conventions** every inline cell follows, so the caller passes
  the record plus a few scalars instead of writing value/payload/optimistic logic:
  - The form starts from `record[field]` — pass `record` + `field`, not a `value`
    or `recordId`. `field` is typed `keyof TRecord`, so a typo won't compile, and
    `TRecord` is inferred from `record` (no explicit type argument needed).
  - Request payload is always `{ [param]: { [field]: value }, return_to }`.
  - The optimistic update replaces that record inside one page `collection`; you
    only supply `toRecordPatch`.
  - `errorFrom` is **optional** — it defaults to `errors[field] || errors.base`
    with a humanized fallback message. Pass it only when a field surfaces another
    field's error (see tracking number below).

```tsx
// app/frontend/pages/Warehouses/Show/InlineYourFieldEditor.tsx
import FormError from "@/components/FormError";
import { InlineCellForm, InlineCellTrigger } from "@/components/InlineCellEditor";
import { useInlineCellForm } from "@/lib/useInlineCellForm";
import type { WarehousePurchaseItemRecord } from "../types";

type YourFieldEditorProps = {
  item: WarehousePurchaseItemRecord;
  isOpen: boolean;
  onClose: () => void;
  onOpen: () => void;
  onSaved: (itemId: number) => void;
  returnTo: string;
};

export function InlineYourFieldEditor({
  item, isOpen, onClose, onOpen, onSaved, returnTo,
}: YourFieldEditorProps) {
  const { error, onChange, save, value } = useInlineCellForm({
    isOpen,
    record: item,
    field: "your_field",
    returnTo,
    updatePath: item.your_field_update_path,
    param: "purchase_item",
    collection: "purchase_items",
    toRecordPatch: (yourField) => ({ your_field: yourField }),
    onClose,
    onOpen,
    onSaved: () => onSaved(item.id),
  });

  if (!isOpen) {
    return (
      <InlineCellTrigger ariaLabel="Edit your field" onOpen={onOpen}>
        {item.your_field ? <span>{item.your_field}</span> : null}
      </InlineCellTrigger>
    );
  }

  return (
    <InlineCellForm onCancel={onClose} onSave={save}>
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
  );
}
```

**Custom `toRecordPatch`** handles type conversion and denormalized columns: the
shipping company editor sends a string id but optimistically writes both
`shipping_company_id` (a number) and the denormalized `shipping_company_name`.

**Custom `errorFrom`** is only needed for cross-field errors. Tracking number
passes one because a blank shipping company surfaces as a `shipping_company_id`
error on the tracking save:

```tsx
errorFrom: (errors) =>
  errors.tracking_number || errors.shipping_company_id || errors.base || "Could not save tracking number",
```

**Client-side pre-checks** (a field that requires another, like tracking number
requiring a shipping company) stay in the editor — never in the shared hook.
Hold a small local error state, guard inside an `onSave` wrapper before calling
`save()`, and derive the displayed error
(`requiresOther ? localError : serverError`). See `InlineTrackingNumberEditor`.

### 9. Wire into the table row

In `PurchaseItemRow` (`PurchaseItemsSection.tsx`). The open state lives on the
row (not the shell) so sibling editors can coordinate — e.g. opening tracking
auto-opens shipping. Memoize the open/close callbacks (`react-perf`):

```tsx
const [isYourFieldOpen, setYourFieldOpen] = useState(false);
const openYourFieldEditor = useCallback(() => setYourFieldOpen(true), []);
const closeYourFieldEditor = useCallback(() => setYourFieldOpen(false), []);

// In the JSX:
<td>
  <InlineYourFieldEditor
    item={item}
    isOpen={isYourFieldOpen}
    onClose={closeYourFieldEditor}
    onOpen={openYourFieldEditor}
    onSaved={onPurchaseItemSaved}
    returnTo={returnTo}
  />
</td>
```

### 10. Component test

Add cases to `Show.test.tsx` using `screen.getByRole("button", { name: "Edit your field" })` to open the editor, interact with the input, and assert the patch call and optimistic update.

---

## Key invariants

- One field = one route + one controller + one policy method. Never combine two fields into one PATCH.
- The controller always redirects (never renders). Errors go via `inertia: inertia_errors(...)`.
- The `return_to` param is always forwarded from the frontend and used by the controller.
- The frontend never re-implements backend validation — it only shows errors returned by the server.
- Pre-submit client-side checks (like the shipping-required guard on tracking) live in the editor, not the shared hook.

## Deliberate limits (don't abstract these yet)

The remaining repeated props — `param: "purchase_item"`, `collection:
"purchase_items"`, and `returnTo` — are **resource/page constants**, identical
across every purchase-item cell. They are intentionally left explicit:

- **A per-resource wrapper** (`usePurchaseItemCell` binding `param` + `collection`)
  is the right way to remove them, but only once a **third** purchase-item field
  editor exists (rule of three). With two, the wrapper is more indirection than
  it saves. When you add the third, extract it then.
- **Deriving `updatePath` from `field`** would need the backend to standardize its
  path prop names (`tracking_update_path` vs `shipping_company_update_path` don't
  follow one rule today). Don't parse paths on the frontend to fake a convention;
  fix the contract first or keep `updatePath` explicit.
