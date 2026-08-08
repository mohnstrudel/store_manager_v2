# 02. Proactive media integrity sweep + scheduler wiring

Spec: ../spec.md
Status: done
Blocked by: none

## What to build

Nothing proactively checks whether a `Media`'s files still exist in R2. The only existing check, `Product::Shopify::Media::Upsert#needs_image_attachment?`, runs solely when a product happens to be synced from Shopify (manual button, or the bulk seed job), and it covers only the original blob — not the preprocessed `thumb`/`preview`/`nano` variants that `thumb_url` actually renders.

Add `Shopify::MediaIntegritySweepJob`: a batch job that walks Product-owned `Media`, checks storage existence for the original blob and each variant record, and repairs what it finds broken.

- Variant file missing, original present → destroy that `ActiveStorage::VariantRecord`. Rails regenerates the preprocessed variant lazily from the intact original on the next `.representation` call.
- Original file missing → enqueue `Shopify::PullProductJob.perform_later(shopify_store_id)` for the owning product, deduped so a product with several broken media is enqueued once. Reuses the existing, tested self-heal in `Upsert#needs_image_attachment?`.
- Everything present → no action.

Wire it into `lib/tasks/scheduler.rake` beside the existing Heroku Scheduler task, so it can be scheduled nightly the way `supervise_sales_webhook` already is.

### Three things the query and the loop must handle

1. **Scope to Products.** `Media` is polymorphic (`mediaable_type`) and also backs `PurchaseItem` and `Warehouse` — `spec/factories/media.rb` has `:for_warehouse` and `:for_purchase_item` traits, so unscoped batching will hit them. Filter with `Media.where(mediaable_type: "Product")`. Those owners are out of scope and have no `shopify_info` at all.
2. **Products need not be Shopify-linked.** Use `product.shopify_store_id` (`app/models/concerns/shopable.rb:27`), which returns `nil` safely, and skip when blank. Do **not** use `product.shopify_info.store_id` — it raises `NoMethodError` on a locally-created product.
3. **Isolate errors per media.** `blob.service.exist?` returns false only on a 404; network and R2 5xx errors raise. Without a rescue around each media, one transient failure aborts the whole nightly sweep mid-batch. `Upsert#needs_image_attachment?:64-70` already models rescue-log-continue; follow it.

## Acceptance criteria

- [x] A `Media` whose original blob and all variant records exist in storage produces no action.
- [x] A `Media` whose original blob is missing enqueues exactly one `Shopify::PullProductJob` for the owning product.
- [x] Two broken `Media` on the same product enqueue one `Shopify::PullProductJob`, not two.
- [x] A `Media` whose original is present but whose variant record's file is missing has that specific `ActiveStorage::VariantRecord` destroyed and enqueues no `Shopify::PullProductJob`.
- [x] A broken `Media` owned by a `Warehouse` or `PurchaseItem` is skipped without error and enqueues nothing.
- [x] A broken `Media` on a `Product` with a blank `shopify_store_id` is skipped without error and enqueues nothing.
- [x] When `blob.service.exist?` raises for one `Media`, that one is logged and skipped and the remaining media in the batch are still processed.
- [x] `bin/rails scheduler:heal_media_integrity` enqueues `Shopify::MediaIntegritySweepJob`.

## Anchors

- `app/models/product/shopify/media/upsert.rb:57-70` — `needs_image_attachment?` is the existing pattern for `blob.service.exist?(blob.key)` plus rescue-and-continue. Follow it rather than inventing a second approach.
- `app/models/concerns/shopable.rb:27` — `shopify_store_id`, the nil-safe accessor to use.
- `app/jobs/shopify/pull_product_job.rb:7` — `perform(shopify_product_id)` signature.
- `app/jobs/migrate_images_to_media_job.rb:6,15` — the existing `BATCH_SIZE = 500` / `in_batches(of: BATCH_SIZE)` pattern to mirror. Note ticket 03 deletes this file; copy the pattern before it goes, or read it from git history.
- `lib/tasks/scheduler.rake:3-9` — the `namespace :scheduler` block containing `task supervise_sales_webhook: :environment`. Add the new task inside the same namespace.
- ActiveStorage internals (`activestorage-8.1.3`): `ActiveStorage::Blob has_many :variant_records` (`app/models/active_storage/blob/representable.rb:9`); `ActiveStorage::VariantRecord belongs_to :blob` and `has_one_attached :image` — so a variant's storage key is reached through its own `image.blob`, like any other attachment.

## Failure and recovery

- If `Shopify::PullProductJob` later fails (Shopify API error), that is existing, already-handled behaviour in that job. This ticket owns detecting breakage and triggering the existing recovery, not the recovery's own error handling.
- Safe to re-run: re-enqueuing `Shopify::PullProductJob` for a product a previous run already healed is a no-op, guaranteed by `needs_image_attachment?`.
- A storage error on one media must not fail the job. Log and continue (acceptance criterion above).

## Non-goals

- `PurchaseItem` and `Warehouse` media are not covered — no external source of truth, so a missing file there is not auto-fixable. Skip them; do not extend the sweep.
- No request-time or live healing. Batch only; must not be invoked from any controller or view path.
- Do not change `Product::Shopify::Media::Upsert` or `Product::Shopify::MediaImporting`. The sweep calls the existing `Shopify::PullProductJob` entry point and duplicates none of the import logic. (Ticket 01 removes one line from `Upsert#attach_image`; that edit belongs to 01 and the two tickets do not otherwise overlap.)
- Destroying an `ActiveStorage::VariantRecord` purges its own variant file, because `VariantRecord`'s `has_one_attached :image` keeps ActiveStorage's `:purge_later` default and ticket 01 does not change it. This is intentional and harmless — the branch only runs when that file is already missing — but do not "fix" it, and do not extend the variant branch to files that still exist.

## Focused verification

- `mise exec -- bin/rspec spec/jobs/shopify/media_integrity_sweep_job_spec.rb --format progress --color` — proves all eight acceptance criteria for the job.
- `mise exec -- bin/rails scheduler:heal_media_integrity` against the dev database, confirming the job is enqueued. There is no spec file for `lib/tasks/scheduler.rake` today and this ticket does not add one; verify the task by hand.
