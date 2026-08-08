# 03. Remove legacy HasPreviewImages images attachment and its dead migration job

Spec: ../spec.md
Status: done
Blocked by: none

## What to build

`HasPreviewImages` (mixed into `Product`, `PurchaseItem`, `Warehouse`) still declares a legacy `has_many_attached :images, dependent: :purge_later`, marked `TODO: Remove after #99`. That issue is done: nothing writes to `.images`, and its only reader is `MigrateImagesToMediaJob` — a one-time backfill with zero callers anywhere in the codebase.

That migration attached the *same blob* to `Media` rather than a copy, so the legacy attachment's `dependent: :purge_later` is still a live deletion path: destroying a `Product`/`PurchaseItem`/`Warehouse` purges a blob a `Media` row may still need, through a route ticket 01 does not touch. Since nothing uses it, the fix is removal rather than a guard. Delete the declaration, and delete the now-purposeless `MigrateImagesToMediaJob` and its spec with it.

Leave the existing `ActiveStorage::Attachment` rows (`name: "images"`) in the database. Removing the Rails declaration makes them invisible to the app, which is the whole point.

## Two consequences to expect (both accepted, neither is a bug to fix here)

1. **Those rows are currently protecting their blobs.** `db/schema.rb:585` adds a foreign key from `active_storage_attachments` to `active_storage_blobs`, and `ActiveStorage::Blob#purge` rescues `ActiveRecord::InvalidForeignKey` and then skips the file delete (`activestorage-8.1.3/app/models/active_storage/blob.rb:335-339`). So any blob shared between a `Media#image` and a legacy `images` row survives purging today. Leaving the rows preserves that. Do not delete them here.
2. **Owner destroys will now leave dangling rows.** After this change, destroying a `Product`/`PurchaseItem`/`Warehouse` leaves its `images` attachment rows pointing at a deleted `record_id`. They keep FK-protecting their blobs indefinitely, so those files can never be reclaimed by ticket 04. Ticket 05's audit reports the wasted bytes; cleaning it up is out of scope for this iteration.

## Acceptance criteria

- [x] `Product`, `PurchaseItem`, and `Warehouse` no longer respond to `.images` — the `has_many_attached :images` declaration is gone from `HasPreviewImages`.
- [x] `MigrateImagesToMediaJob` no longer exists in the codebase.
- [x] Destroying a `Product`/`PurchaseItem`/`Warehouse` touches no legacy attachment and deletes no file (the association is gone, not gated).
- [x] The `has_many :media`, `prev_image_id`, and `next_image_id` behaviour of `HasPreviewImages` is unchanged.
- [x] No remaining reference to `MigrateImagesToMediaJob` or the legacy `.images` attachment in `app/`, `lib/`, or `spec/`.

## Anchors

- `app/models/concerns/has_preview_images.rb:11-24` — the `has_many_attached :images, dependent: :purge_later do |attachable| ... end` block inside `included do`. Delete it entirely. Leave `has_many :media, ...`, `include Media::FormHandling`, `prev_image_id`, and `next_image_id` untouched.
- `app/jobs/migrate_images_to_media_job.rb` (43 lines, whole file) — delete. Ticket 02 borrows its `BATCH_SIZE = 500` / `in_batches` pattern; if 02 has not landed yet, that pattern is still in git history.
- `spec/jobs/migrate_images_to_media_job_spec.rb` (296 lines, whole file) — delete.
- Verified by repository-wide grep this session: `.images` appears only in these three files. No controller, rake task, scheduler entry, serializer, factory, frontend component, or other spec references `MigrateImagesToMediaJob`, `.images`, or `images_attachments`.

## Non-goals

- Do not delete or purge the `ActiveStorage::Attachment` rows with `name: "images"`, or their blobs. See consequence 1 above — those blobs are shared with live `Media#image` attachments, and the rows are what currently prevents them being deleted.
- Do not change `Media::FormHandling` or anything under the `media` association. This ticket removes the separate legacy attachment only.
- Ticket 01 is independent — no ordering dependency in either direction.

## Focused verification

- `mise exec -- bin/rspec spec/models/product_spec.rb spec/models/purchase_item_spec.rb spec/models/warehouse_spec.rb spec/models/concerns/has_preview_images_spec.rb --format progress --color` (drop the last path if no such spec exists) — proves the three including models still load and behave correctly with the attachment removed.
- `grep -rn "MigrateImagesToMediaJob\|\.images\b" app lib spec --include="*.rb"` returns nothing. Part of the ticket, not a separate gate.
- No frontend check applies; this is backend-only.
