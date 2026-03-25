# Sales View Refactor Plan

This file is a project-level reference for the `Sales` view refactor that has now been implemented. It is intentionally self-contained so the same pattern can be reused in other resource folders later.

## Goal

- Keep `Sales` root templates short.
- Organize partials by screen ownership instead of keeping unrelated partials together in `app/views/sales`.
- Keep resource-local reused fragments inside `sales/`.
- Keep only truly cross-resource fragments in `app/views/_shared`.

## What This Captures

- the target structure now used by `app/views/sales`
- the naming moves that made the folder easier to navigate
- the reusable screen-first rules for future refactors

## Target Tree

```text
app/views/sales/
  edit.html.slim
  index.html.slim
  new.html.slim
  show.html.slim
  form/
    _form.html.slim
    _product_fields.html.slim
  index/
    _sync_modal.html.slim
    _table.html.slim
    _sale.html.slim
  items/
    _link_button.html.slim
    _purchase_item_warehouse.html.slim
    _purchase_items.html.slim
  show/
    _address.html.slim
    _attributes.html.slim
    _header.html.slim
    _items.html.slim
```

## Naming Moves

- `_modal_sync_menu` -> `index/_sync_modal`
- `_sale` -> `index/_sale`
- `_sale_attributes` -> `show/_attributes`
- `_sale_address` -> `show/_address`
- `_sale_items` -> `show/_items`
- `_form` -> `form/_form`
- `_product_fields` -> `form/_product_fields`
- `_link_btn` -> `items/_link_button`
- `_purchase_items` -> `items/_purchase_items`
- `_purchase_item_warehouse` -> `items/_purchase_item_warehouse`

## Root Template Shape

### `index.html.slim`

- Keep notice and nav in the root file.
- Render sync modal from `sales/index/sync_modal`.
- Render table from `sales/index/table`.
- Use explicit collection rendering:

```slim
tbody
  = render partial: "sales/index/sale", collection: @sales, as: :sale
```

### `show.html.slim`

- Keep the root file as a small composition layer:
  - notice
  - `render "sales/show/header", sale: @sale`
  - page wrapper
  - `render "sales/show/items", sale: @sale`
  - `render "sales/show/attributes", sale: @sale`
  - `render "sales/show/address", sale: @sale`

### `new.html.slim` and `edit.html.slim`

- Keep only page shell code in the root files.
- Render the shared form from `sales/form/form`.

## Helper Boundary

- Keep view-only links, button markup, and HTML helpers in `app/helpers/sale_helper.rb`.
- Do not move screen-only presentation helpers into the `Sale` model.
- Revisit helper splitting only after the file layout is cleaned up.

## Migration Sequence

1. Create `show/` and move show-only partials there.
2. Create `index/`, move row and modal partials there, and extract the table.
3. Create `form/`, move the shared form shell and nested product fields there.
4. Create `items/` for sales-local reused fragments shared by `index` and `show`.
5. Update render paths to explicit screen-local partial paths.
6. Run the relevant specs and manually verify `/sales`, `/sales/:id`, `/sales/new`, and `/sales/:id/edit`.

## Rollout After Sales

If this works well, apply the same screen-first pattern to:

- `products`
- `purchases`
- `warehouses`

The rule stays the same: organize by screen first, then by local widget or variant.
