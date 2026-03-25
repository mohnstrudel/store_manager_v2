# CRUD View Refactor Pattern

Use this reference for simple CRUD resources whose view layer mostly consists of:

- one index row partial
- one shared form partial
- one show page with a details table
- optionally one related records table

## Default Target Tree

```text
app/views/<resource>/
  edit.html.slim
  index.html.slim
  new.html.slim
  show.html.slim
  form/
    _form.html.slim
  index/
    _resource.html.slim
    _table.html.slim
  show/
    _details.html.slim
    _related_records.html.slim
```

## Default Rules

- Keep `index.html.slim` as a small wrapper around notice, nav, and `index/_table`.
- Move the list row into `index/_resource.html.slim` and render it explicitly with `render partial:`.
- Keep `new.html.slim` and `edit.html.slim` as page shells that render `form/_form`.
- Move the main record table on `show` into `show/_details.html.slim`.
- Move any related collection on `show` into its own screen-local partial such as:
  - `show/_products.html.slim`
  - `show/_purchases.html.slim`
  - `show/_purchase_items.html.slim`
- If a related collection table becomes action-heavy or repeats complex cell markup, add one more nested subtree under that section:
  - `show/purchase_items/_row.html.slim`
  - `show/purchase_items/_actions.html.slim`
  - `show/purchase_items/_sale.html.slim`

## Validated Examples In This Repo

- `brands`
- `colors`
- `franchises`
- `shapes`
- `sizes`
- `suppliers`
- `shipping_companies`
- `versions`

## Naming Guidance

- Drop repeated prefixes once folder context exists.
- Prefer:
  - `_details`
  - `_products`
  - `_purchases`
  - `_table`
- Avoid:
  - `_resource_details`
  - `_resource_products`
  - `_resource_table`

## Exceptions

- If one action is not really part of the CRUD surface, do not force it into the same pattern.
- Example: a sign-up page or auth-specific `new` screen can stay custom if it has different routing, copy, or layout expectations.
- If the show page becomes section-heavy, switch to `screen-first-view-pattern.md` instead of stretching this simple CRUD shape too far.
- If the controller can normalize UI state or preload a related collection once, pass that explicit collection into the show section instead of reaching through associations in nested partials.
