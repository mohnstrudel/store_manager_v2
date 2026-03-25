# Rails View Organization

Use this file for the repo-specific view organization pattern.

## Core Rules

- Keep root templates small: `index.html.slim`, `show.html.slim`, `new.html.slim`, `edit.html.slim`.
- Organize by screen first:
  - `index/`
  - `show/`
  - `form/`
  - `items/` when a fragment is reused across screens inside one resource
- Keep only truly cross-resource fragments in `app/views/_shared`.
- Keep endpoint-owned `*.turbo_stream.*` templates at the resource root.

## Default Baseline

Use this when the resource is simple:

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

## Expand When Needed

Expand beyond the baseline when the resource has:
- several show sections
- nested or repeatable form fields
- screen-owned modals
- resource-local fragments shared across screens

Then allow shapes like:
- `show/_header`
- `show/_section`
- `show/<section>/_row`
- `index/_sync_modal`
- `show/_store_sync_modal`

## What Codex Often Gets Wrong

- Do not keep adding new root-level partials after a screen subtree exists.
- Do not move a fragment to `_shared` just because it is reused twice inside one resource.
- Do not extract tiny one-line cell partials that are harder to discover than the inline markup.
- Do not query option collections directly from heavy form templates; prepare them at the controller boundary.
- Do not let deep partials read `params` when explicit UI state can be passed once.

## Repo Examples

- simple baseline resources:
  - `brands`
  - `colors`
  - `franchises`
  - `shapes`
  - `sizes`
  - `suppliers`
  - `shipping_companies`
  - `versions`
- expanded screen-first resources:
  - `sales`
  - `products`
