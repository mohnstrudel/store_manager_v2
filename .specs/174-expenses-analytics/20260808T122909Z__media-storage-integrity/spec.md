# Media storage integrity: stop breaking sales-page images, heal what broke, reclaim what is dead

## Problem

Product images (rendered on Sales pages via `thumb_url(item.product)`, `app/helpers/sale_helper.rb:290,308` → `app/helpers/ui_helper.rb:4`) intermittently 404 in production.

### Evidence

- **Fact** — `config/storage.yml` defines a single `cloudflare` R2 service, and all three deployed environments use it (`development.rb:60`, `staging.rb:43`, `production.rb:46`). Bucket and account come from `ENV["CLOUDFLARE_BUCKET"]` / `ENV["CLOUDFLARE_ACCOUNT_ID"]`. Per the user, this bucket is deliberately shared across environments.
- **Fact** — `Product::Shopify::MediaImporting#remove_obsolete_shopify_media` (`app/models/product/shopify/media_importing.rb:16-25`) calls `.destroy_all` on `Media` rows whose blob checksum does not match a freshly downloaded Shopify file.
- **Fact** — in `activestorage-8.1.3`, `has_one_attached` / `has_many_attached` default to `dependent: :purge_later` (`lib/active_storage/attached/model.rb:108,210`). Purging is triggered from the **attachment row**, not the owning record: `ActiveStorage::Attachment` declares `after_destroy_commit :purge_dependent_blob_later` (`app/models/active_storage/attachment.rb:37`), which reads the `dependent` option off the reflection at destroy time (`attachment.rb:150-155`).
- **Fact** — because the trigger is the attachment row, **replacing** an image purges the old file just as much as destroying the record does. Both `Media::FormHandling#update_media_from_form!` (`app/models/media/form_handling.rb:47`) and `Product::Shopify::Media::Upsert#attach_image` (`app/models/product/shopify/media/upsert.rb:50`, an explicit `.purge`) hit that path, in every environment.
- **Fact** — a self-heal path exists but is not proactive: `Upsert#needs_image_attachment?` (`app/models/product/shopify/media/upsert.rb:57-70`) checks `!blob.service.exist?(blob.key)` and re-downloads from Shopify, but only when a product is synced — the manual "Pull from Shopify" button or the bulk seed job. There is no product webhook controller and no scheduled resync (`lib/tasks/scheduler.rake` has only `supervise_sales_webhook`), so production never re-checks a product's images unless a human clicks that button.
- **Fact** — that check covers only the original blob, not the preprocessed `thumb`/`preview`/`nano` variants that `thumb_url` actually renders via `.representation(:thumb)`. A variant whose R2 object goes missing while the original is intact is invisible to today's self-heal.
- **Fact** — `MigrateImagesToMediaJob` (`app/jobs/migrate_images_to_media_job.rb:39`) backfilled `Media` by attaching the **same blob** (`media.image.attach(img.blob)`), never detaching it from the legacy `images` attachment. `Product`, `PurchaseItem`, and `Warehouse` still declare that attachment through `HasPreviewImages` (`app/models/concerns/has_preview_images.rb:11`, marked `TODO: Remove after #99`).
- **Fact** — per the user, #99 is complete. Repository-wide grep confirms `.images` appears only in `has_preview_images.rb:11`, `migrate_images_to_media_job.rb`, and `spec/jobs/migrate_images_to_media_job_spec.rb`. The job has zero callers in `app/`, `lib/`, or `config/`. Nothing in the frontend, serializers, factories, or rake tasks touches it.
- **Fact** — `db/schema.rb:585` adds a foreign key from `active_storage_attachments` to `active_storage_blobs`, and `ActiveStorage::Blob#purge` rescues `ActiveRecord::InvalidForeignKey` and then skips the file delete (`blob.rb:335-339`). So today a blob shared between `Media#image` and a legacy `images` row is silently protected from purging; a blob with no legacy row is not.
- **Fact** — per the user: a production database backup is periodically copied by hand into local and staging. Separately, every environment can re-pull products and sales from Shopify independently (`lib/tasks/db_fill.rake` → `Shopify::PullProductsJob`). Copies flow production → local/staging only, never back.
- **Fact** — per the user: one R2 bucket, shared by all environments, is a settled arrangement and is not changing.

### Diagnosis

Confirmed, not inferred. Because a production database backup is restored into local and staging, those environments hold `Media` rows carrying **production's own blob keys**. Because the bucket is shared, those keys resolve to production's real files. Any delete performed in local or staging therefore deletes a file production is still serving.

The concrete chain: restore the production backup into staging, then re-pull products from Shopify there. `remove_obsolete_shopify_media` (`app/models/product/shopify/media_importing.rb:16-25`) destroys every `Media` whose stored blob checksum does not match the freshly downloaded file — and destroy purges. Every such row was pointing at a production key. Production's own row is untouched by staging's destroy, so it survives, dangling, and its image 404s.

That is the whole bug class, and it has four live entry points, not one: record destroy, image replacement, `Upsert`'s explicit purge, and legacy-attachment purge on owner destroy. All four are reachable from local and staging today.

The invariant that follows, and that the rest of this spec is built on: **production's database is the only authority for what exists in the bucket.** Local and staging always hold a stale copy of it, so no deletion decision may ever be made from those environments.

## Goal and approach

**The bucket stays shared.** Separating buckets per environment would close all four entry points at the infrastructure layer, but the user has settled on one bucket, so that option is closed and not revisited here. The consequence is that the application must enforce the authority invariant itself: local and staging can read the bucket freely, and must never delete from it. Slice A is what makes that true, and it is the urgent one — until it ships, a single Shopify re-pull in staging after a database restore can take out production images.

### A. Make file deletion a single, gated, deferred path

Today four code paths delete R2 objects synchronously and unconditionally. Replace that with one deletion path that any environment can be denied.

1. Introduce one policy flag, set explicitly per environment:

   ```ruby
   # config/environments/production.rb, test.rb
   config.x.storage.delete_files = true
   # config/environments/development.rb, staging.rb
   config.x.storage.delete_files = false
   ```

   Unset reads as `nil`, so the safe answer is the default. Slices A, C, and D all read this one flag.

2. Turn off ActiveStorage's automatic purging for `Media#image` by passing `dependent: false` explicitly:

   ```ruby
   has_one_attached :image, dependent: false do |attachable|
     ... # variants unchanged
   end
   ```

   **`dependent:` must be passed, not omitted.** Omitting it leaves the default `:purge_later` and changes nothing.

3. Delete the redundant explicit purge in `Upsert#attach_image` (`app/models/product/shopify/media/upsert.rb:50`). `attach` already replaces the attachment; the `.purge` only adds an ungated, immediate file delete.

4. Add no per-model purge callback. Once `dependent: false` is set, a destroyed or replaced `Media` image leaves its blob with no attachment rows — i.e. it lands in `ActiveStorage::Blob.unattached` (`blob.rb:46`, `where.missing(:attachments)`) and is collected by slice C. That is what makes A and C one design rather than two: A stops every environment from deleting, C gives production a gated way to delete on a schedule.

The cost is that production reclaims storage on the sweep cadence rather than instantly. For an image store that is a fair trade, and it is the only version of this that is also correct for image *replacement*, which a record-level callback cannot see.

### A2. Remove the legacy `images` attachment rather than guard it

Delete `has_many_attached :images, dependent: :purge_later` from `HasPreviewImages` (`app/models/concerns/has_preview_images.rb:11`) outright, and delete the now-purposeless `MigrateImagesToMediaJob` and its spec.

Leave the existing `ActiveStorage::Attachment` rows (`name: "images"`) in the database. Removing the declaration makes them invisible to the app, which is the point. Two consequences to record, both accepted:

- Those rows currently *protect* their blobs from purging via the foreign key described above. Leaving them keeps that protection. Deleting them later would remove it — see Boundaries.
- After the change, destroying a `Product`/`PurchaseItem`/`Warehouse` leaves its `images` attachment rows behind pointing at a dead `record_id`. They keep FK-protecting their blobs indefinitely, so those files can never be reclaimed by slice C. Slice D reports them.

### B. Proactive nightly sweep that finds and heals broken images

New `Shopify::MediaIntegritySweepJob`, wired into `lib/tasks/scheduler.rake` beside the existing `supervise_sales_webhook` task, run nightly:

1. Batch over `Media.where(mediaable_type: "Product").joins(image_attachment: :blob)`. The `mediaable_type` filter is required — `Media` is polymorphic and also backs `PurchaseItem` and `Warehouse`, which are out of scope and have no `shopify_info`.
2. Check `blob.service.exist?(blob.key)`, and separately check each of the blob's `variant_records` (own attached image → blob → key).
3. Variant missing, original intact → destroy that `ActiveStorage::VariantRecord`. The preprocessed variant regenerates lazily from the good original on the next `.representation` call; no Shopify call needed.
4. Original missing → collect the owning product, deduped, and enqueue `Shopify::PullProductJob.perform_later(product.shopify_store_id)`, reusing the tested `Upsert#needs_image_attachment?` self-heal. Skip products where `shopify_store_id` is blank; not every product is Shopify-linked.
5. Isolate errors per media. `blob.service.exist?` raises on anything that is not a 404, so one transient R2 error must not abort the batch. `Upsert#needs_image_attachment?:64-70` already models the rescue-and-continue pattern.

Detection is one HEAD request per file. Recovery fires only for the broken subset, so nightly cadence will not stress Shopify's API.

### C. Reclaim unattached blobs — the one path allowed to delete from R2

New `Storage::ReclaimUnattachedBlobsJob`, scheduled weekly, gated on `config.x.storage.delete_files`:

```ruby
ActiveStorage::Blob.unattached.where(created_at: ..GRACE_PERIOD.ago).find_each(&:purge_later)
```

- `unattached` is Rails' own scope (`blob.rb:46`) — blobs no attachment row references. These are genuinely dead: replaced images, media destroyed by the Shopify obsolete-media cleanup, blobs left behind when `Media::FormHandling#resolve_attachable` resolved a signed ID but the subsequent `media.create!` failed.
- The grace period (default 2 days) exists because a blob row can legitimately exist for a short window before its attachment does. Do not remove it.
- `Blob#purge` cascades correctly: `before_destroy { variant_records.destroy_all }` (`blob/representable.rb:9-10`) destroys the variant records, whose own attachments purge the variant files. `config.load_defaults 7.0` (`config/application.rb:14`) leaves `ActiveStorage.track_variants` at `true`, so every variant file has its own blob row and is reachable this way.
- `Blob#purge` rescues `ActiveRecord::InvalidForeignKey`, so a blob still referenced by a legacy `images` row is skipped rather than raising.

This is the mechanism that makes slice A's storage accounting correct. Without it, production leaks every replaced and destroyed image.

### D. Audit R2 for objects the database does not know about

The bucket can also hold objects with **no** `active_storage_blobs` row at all — a process that died between `Blob#purge`'s row destroy and its file delete, or rows removed by `delete_all` bypassing callbacks. Slice C cannot see these, because it works from the database side.

Cloudflare R2 offers no server-side mechanism for this. Confirmed against current docs:

- **Object lifecycle rules** (<https://developers.cloudflare.com/r2/buckets/object-lifecycles/>) support age-based deletion, date-based expiration, storage-class transitions, and aborting incomplete multipart uploads. Rules are scoped by **key prefix**, up to 1000 per bucket, set via dashboard, `wrangler r2 bucket lifecycle add|set`, or S3 `PutBucketLifecycleConfiguration`. ActiveStorage keys are flat random strings with no prefix structure and no age correlation to liveness — a three-year-old image is usually still in use. **Lifecycle rules cannot express "delete what the database does not reference" and must not be used for it.**
- **Deletion paths** (<https://developers.cloudflare.com/r2/objects/delete-objects/>) are the dashboard (objects, folders, or Empty Bucket), `wrangler r2 object delete <bucket>/<key>`, the Workers binding, and the S3 API. All require an explicit key or prefix.

So the diff must be computed by the application, using the S3 client ActiveStorage already configures. No new dependency and no Cloudflare API token: `aws-sdk-s3` is already in the Gemfile (`Gemfile:63`) and `ActiveStorage::Service::S3Service` exposes `attr_reader :client, :bucket` (`lib/active_storage/service/s3_service.rb:15`).

New `Storage::BucketOrphanAudit`:

1. Load every `active_storage_blobs.key` into a `Set`.
2. Page through `blob_service.bucket.objects` (`ListObjectsV2`; R2's S3 docs recommend V2 over `ListObjects`).
3. Report every bucket key absent from the set, with count and total bytes.

**Report-only by default.** Deleting requires both `config.x.storage.delete_files` and an explicit `CONFIRM=yes`. Because the flag is true only in production, that combination also enforces the authority invariant: the delete can only ever run where the authoritative database lives.

The trade-off it carries, now that the database-copy practice is confirmed: local and staging re-pull from Shopify independently, so they upload blobs under keys production has never seen. From production those look exactly like orphans. Deleting them reclaims real storage and breaks images in local and staging until those environments re-pull — recoverable, but a genuine interruption. That is a judgement call for the user, which is why the audit reports and the delete asks.

Two ops items belong here and need no code:

- Add an R2 lifecycle rule to abort incomplete multipart uploads. Pure hygiene, one `wrangler r2 bucket lifecycle add` call.
- If images keep disappearing before slice A ships, an R2 **bucket lock** (`wrangler r2 bucket lock add <bucket> --name <name> --retention-days N`) blocks all deletes at the storage layer, from every environment, regardless of application code. Blunt — it also blocks slice C, and it is the one thing that would hold even against a stray console session — but it is the only zero-code way to stop the bleeding today.

## Approved decisions

- One shared R2 bucket across all environments, with production database backups copied by hand into local and staging. — confirmed by the user; settled, not revisited. This is what makes application-level deletion gating necessary rather than optional.
- Production's database is the sole authority for what exists in the bucket; local and staging never delete. — follows from the above, and is the rule slices A, C, and D implement.
- Purge-safety (A), detection and healing (B) both in scope. — approved, unchanged
- Legacy `HasPreviewImages` `images` attachment removed outright rather than guarded (A2); `MigrateImagesToMediaJob` and its spec deleted alongside. — approved, unchanged
- Sweep cadence nightly, full catalog, detection and recovery decoupled. — approved, unchanged
- Recovery reuses `Shopify::PullProductJob` / `Upsert` self-heal rather than a new upload pipeline. — approved, unchanged
- Broken-variant-only case repaired by deleting the `VariantRecord`, not a full Shopify re-pull. — approved, unchanged
- **Revised — needs a nod.** A1 was approved as "`Media#image` purge guarded to production-only" via a `before_destroy` callback that omits the `dependent:` option. That implementation does not work: omitting `dependent:` keeps the `:purge_later` default, `before_destroy` purges ahead of commit so a rollback would delete a live file, and a record-level callback cannot see image *replacement*, which is the more frequent purge trigger. Revised to: `dependent: false` explicitly, no per-model callback, one `config.x.storage.delete_files` flag, and deletion deferred to slice C.
- **New — needs a nod.** Slice C, production-gated reclamation of unattached blobs, weekly.
- **New — needs a nod.** Slice D, report-only R2 bucket audit, with deletion gated on production plus an explicit confirmation.

## Contracts

No public or API contract changes. Internal additions:

- `config.x.storage.delete_files` — per-environment flag, the single gate on deleting files from the bucket.
- `Shopify::MediaIntegritySweepJob` (new job).
- `Storage::ReclaimUnattachedBlobsJob` (new job).
- `Storage::BucketOrphanAudit` (new model-layer object, `app/models/storage/bucket_orphan_audit.rb`).
- `scheduler:heal_media_integrity` and `scheduler:reclaim_unattached_blobs` in `lib/tasks/scheduler.rake`, wired to Heroku Scheduler by the user outside the codebase, as `supervise_sales_webhook` already is.
- `storage:audit_bucket_orphans` and `storage:delete_bucket_orphans` in a new `lib/tasks/storage.rake`. Operator-run, never scheduled.
- Changed: `Media#image` gains `dependent: false`.
- Removed: `HasPreviewImages`'s `has_many_attached :images`; the `media.image.purge` line in `Upsert#attach_image`; `MigrateImagesToMediaJob`; `spec/jobs/migrate_images_to_media_job_spec.rb`.

## Boundaries and non-goals

- **The shared bucket is not addressed, by decision.** Slices A–D enforce the authority invariant in application code instead. That leaves one residual hazard nothing here can close: any script, console session, or future code that deletes from the bucket while bypassing `config.x.storage.delete_files` will still hit production files from any environment. The flag is a convention the code honours, not a permission boundary R2 enforces.
- `PurchaseItem` and `Warehouse` images stay out of slice B: no external source of truth, so a missing file is not auto-recoverable. They are covered by A, C, and D, which are storage-generic.
- No request-time healing. Detection and recovery stay batch and async; page-load latency is unaffected.
- Slice C reclaims on a schedule, not immediately. Between an image being replaced and the next weekly sweep, its old file still occupies storage in production. Accepted.
- Slice D deletes nothing by default and must not be scheduled.
- Cleaning up the orphaned `ActiveStorage::Attachment` rows (`name: "images"`) is out of scope. **If the user does it later, note that it removes the foreign-key protection those rows currently give their blobs**: every blob whose only remaining reference was a legacy row becomes eligible for slice C to purge on the next run. Delete the attachment rows only, never `.purge`/`.purge_later` them, and expect a larger-than-usual reclamation on the following sweep.
- Ticket 02's variant repair destroys `ActiveStorage::VariantRecord`s, whose own `has_one_attached :image` still carries ActiveStorage's `:purge_later` default. That is a synchronous delete slice A does not gate. It is safe here because the branch only fires when the variant file is already missing, but it is the one remaining ungated path and is recorded as such.
- Slice B heals only `Media`-backed Product images.

## Testing decisions

- `spec/models/media_spec.rb` — replace the existing `"has_one_attached image with dependent: :purge_later"` example (`spec/models/media_spec.rb:22-25`, which only asserts the image is present). Assert that destroying a `Media` enqueues no `ActiveStorage::PurgeJob` and leaves the blob row intact, and that the blob afterwards appears in `ActiveStorage::Blob.unattached`. Assert on the enqueued job rather than mocking `image.purge_later`; the attachment is already destroyed by then, so mocking the proxy is fragile.
- `spec/models/product/shopify/media/upsert_spec.rb` — cover that re-attaching over an existing image no longer deletes the previous file from the service.
- Delete `spec/jobs/migrate_images_to_media_job_spec.rb` with the job.
- `Shopify::MediaIntegritySweepJob` spec — healthy media (no action); original missing (one `Shopify::PullProductJob`, deduped across two broken media on one product); variant missing with original intact (that `VariantRecord` destroyed, no job enqueued); `Media` owned by a `Warehouse` (skipped, no error); Product with blank `shopify_store_id` (skipped, no error); `service.exist?` raising on one media (that media skipped, the rest still processed).
- `Storage::ReclaimUnattachedBlobsJob` spec — unattached blob older than the grace period is purged when the flag is true; the same blob is untouched when the flag is false; an unattached blob newer than the grace period is untouched; an attached blob is untouched. Set the flag per example with `allow(Rails.configuration.x.storage).to receive(:delete_files).and_return(...)`.
- `Storage::BucketOrphanAudit` spec — runs against the `:test` Disk service, not R2. A key present in the bucket with no blob row is reported; a key with a blob row is not; the audit deletes nothing when unconfirmed.

## Open proposals

Both earlier questions are answered and folded into Approved decisions above: the database-copy practice is confirmed (making the diagnosis certain rather than probable), and the single shared bucket is settled.

One item remains for the user, outside the codebase: decide whether to accept slice D's trade-off before ever running `storage:delete_bucket_orphans`. Reclaiming stranded files from production also removes objects local and staging created since their last database restore, which is recoverable by re-pulling from Shopify but is a real interruption. Slice D reports without deleting until that call is made.
