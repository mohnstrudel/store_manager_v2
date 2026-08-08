# 04. Reclaim unattached blobs — the only path allowed to delete from R2

Spec: ../spec.md
Status: done
Blocked by: 01

## What to build

Ticket 01 stops every environment from deleting files synchronously, which means production now leaks: every replaced image, every `Media` destroyed by the Shopify obsolete-media cleanup, and every blob left behind when an upload resolved but the subsequent `media.create!` failed keeps its file forever. This ticket is the other half — the one deletion path, deferred and gated, that gives those files back.

Add `Storage::ReclaimUnattachedBlobsJob` (`app/jobs/storage/reclaim_unattached_blobs_job.rb`):

```ruby
GRACE_PERIOD = 2.days

def perform
  return unless Rails.configuration.x.storage.delete_files

  ActiveStorage::Blob.unattached.where(created_at: ..GRACE_PERIOD.ago).find_each(&:purge_later)
end
```

Log how many blobs were enqueued so a scheduled run leaves a trace worth reading.

Wire `scheduler:reclaim_unattached_blobs` into the existing `namespace :scheduler` block in `lib/tasks/scheduler.rake`, for the user to schedule weekly through Heroku Scheduler.

### Why each piece is what it is

- **`ActiveStorage::Blob.unattached`** is Rails' own scope — `where.missing(:attachments)` (`activestorage-8.1.3/app/models/active_storage/blob.rb:46`). A blob no attachment row references is genuinely dead. This is the safe, database-side definition of waste; do not substitute a hand-written query.
- **The flag gate is the whole point.** Without `config.x.storage.delete_files` (ticket 01), running this job in dev or staging would delete files production still uses — reintroducing the original bug through a new door. Check it first thing and return.
- **The grace period is not optional.** A blob row can legitimately exist for a short window before its attachment does: `Media::FormHandling#resolve_attachable` (`app/models/media/form_handling.rb:59-66`) resolves a signed blob ID and only then calls `media.create!`, so a validation failure or a slow request leaves a brand-new blob briefly unattached. Purging those would delete images users just uploaded.
- **Cascade is already correct.** `ActiveStorage::Blob` declares `before_destroy { variant_records.destroy_all if ActiveStorage.track_variants }` (`app/models/active_storage/blob/representable.rb:9-10`), and each `VariantRecord`'s own attachment purges its variant file. `config.load_defaults 7.0` (`config/application.rb:14`) leaves `track_variants` at `true`, so every variant file has its own blob row and is reclaimed with its original. Do not walk variants by hand.
- **Foreign keys make it forgiving.** `Blob#purge` rescues `ActiveRecord::InvalidForeignKey` (`blob.rb:335-339`), so a blob still referenced by a legacy `images` attachment row (ticket 03 leaves those in place) is skipped rather than raising.

## Acceptance criteria

- [x] With `config.x.storage.delete_files` true, an unattached blob older than the grace period is purged — row gone, file gone.
- [x] With `config.x.storage.delete_files` false, that same blob is untouched — no `ActiveStorage::PurgeJob` enqueued, row and file intact.
- [x] An unattached blob created inside the grace period is untouched in both cases.
- [x] A blob with a live attachment is never purged, regardless of age.
- [x] Purging an unattached original also removes its `ActiveStorage::VariantRecord`s and their files.
- [x] The job logs the number of blobs it enqueued.
- [x] `bin/rails scheduler:reclaim_unattached_blobs` enqueues `Storage::ReclaimUnattachedBlobsJob`.

## Anchors

- `activestorage-8.1.3/app/models/active_storage/blob.rb:46` — the `unattached` scope.
- `activestorage-8.1.3/app/models/active_storage/blob.rb:327-345` — `delete`, `purge`, `purge_later`, and the `InvalidForeignKey` rescue.
- `activestorage-8.1.3/app/models/active_storage/blob/representable.rb:9-10` — the variant-record cascade.
- `app/models/media/form_handling.rb:59-66` — `resolve_attachable`, the reason a grace period is required.
- `lib/tasks/scheduler.rake:3-9` — the `namespace :scheduler` block to extend.
- `app/jobs/shopify/base_pull_job.rb` — the existing namespaced-job and `queue_as` convention to follow.

## Failure and recovery

- Safe to re-run at any cadence: a blob already purged is no longer in `unattached`, and `purge_later` on a missing file is a no-op delete.
- If a single `purge_later` enqueue fails, the blob stays unattached and is picked up by the next run. Do not add bespoke retry logic.
- If the schedule is never wired up, production simply keeps leaking — the same state as before this ticket, not a worse one. Getting the task onto Heroku Scheduler is part of shipping the slice.

## Non-goals

- Do not delete bucket objects that have no `active_storage_blobs` row. That is ticket 05, it needs a bucket listing rather than a database query, and it is not safe while the bucket is shared.
- Do not add immediate purging back to `Media` to shorten the delay. Deferred reclamation is the design; see ticket 01.
- Do not touch `ActiveStorage::VariantRecord` directly — the cascade covers it.
- Do not make the grace period configurable per environment. One constant, one meaning.

## Focused verification

- `mise exec -- bin/rspec spec/jobs/storage/reclaim_unattached_blobs_job_spec.rb --format progress --color` — proves all seven acceptance criteria. Set the flag per example with `allow(Rails.configuration.x.storage).to receive(:delete_files).and_return(true/false)`; specs run against the `:test` Disk service (`config/environments/test.rb:39`), never R2.
- `mise exec -- bin/rails scheduler:reclaim_unattached_blobs` against the dev database, confirming the job is enqueued and that it returns without purging (dev has the flag off).
