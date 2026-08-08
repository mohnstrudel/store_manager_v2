# 05. Audit R2 for objects the database does not know about

Spec: ../spec.md
Status: done
Blocked by: 04

## What to build

Ticket 04 reclaims blobs the database knows are dead. The bucket can also hold objects with **no `active_storage_blobs` row at all** — a process that died between `Blob#purge` destroying the row and deleting the file, or rows removed with `delete_all` bypassing callbacks. Nothing in the database can see those; the only way to find them is to list the bucket and diff.

Add `Storage::BucketOrphanAudit` (`app/models/storage/bucket_orphan_audit.rb`) plus a new `lib/tasks/storage.rake` with two operator-run tasks.

### The audit

1. Load every `active_storage_blobs.key` into a `Set`. With `track_variants` on (see ticket 04), this covers originals, variants, and preview images — the full inventory of what the app expects to exist.
2. Page through the bucket: `ActiveStorage::Blob.service.bucket.objects`, which issues `ListObjectsV2` and paginates lazily. `ActiveStorage::Service::S3Service` exposes `attr_reader :client, :bucket` (`activestorage-8.1.3/lib/active_storage/service/s3_service.rb:15`); `bucket` is an `Aws::S3::Bucket`.
3. Return the keys present in the bucket but absent from the set, with a count and total bytes.

### The tasks

- `storage:audit_bucket_orphans` — reports count, total bytes, and a sample of keys. Deletes nothing. This is the default and the one that is always safe.
- `storage:delete_bucket_orphans` — deletes the audited keys, and must refuse unless **both** `Rails.configuration.x.storage.delete_files` is true **and** `ENV["CONFIRM"] == "yes"`. Delete via `ActiveStorage::Blob.service.delete(key)` (`s3_service.rb:63`), which is the public API. Only reach for `client.delete_objects` (1000 keys per request) if a real audit shows enough orphans to make per-key `DeleteObject` calls impractical, and say so in the log.

### Read this before running the delete task

The bucket is shared by every environment and stays that way. Production's database is the only authority for what exists in it, so **the delete task may only ever run in production**. `config.x.storage.delete_files` is true only there (ticket 01), so checking the flag enforces this — but state the reason in the task output too, because the next person to read it will be holding a production console.

What the delete actually removes, given that local and staging re-pull from Shopify independently and upload blobs under keys production has never seen:

- genuinely stranded files — the ones worth reclaiming;
- **and** every object local or staging created since their last production database restore, which from production is indistinguishable from the first group.

The second group breaks images in those environments until they re-pull from Shopify. That is recoverable but disruptive, and it is the user's call rather than the implementer's — which is why the audit reports and the delete asks for `CONFIRM=yes`. Print both bullets before deleting anything.

The audit task is safe to run at any time and is the useful half day to day: it says how much storage is actually stranded, including the files stranded permanently by the dangling legacy `images` rows described in ticket 03.

### Why not lifecycle rules

Cloudflare R2 lifecycle rules (<https://developers.cloudflare.com/r2/buckets/object-lifecycles/>) support age-based deletion, date-based expiration, storage-class transitions, and aborting incomplete multipart uploads. They are scoped by **key prefix**, capped at 1000 per bucket, and set through the dashboard, `wrangler r2 bucket lifecycle add|set`, or S3 `PutBucketLifecycleConfiguration`. ActiveStorage keys are flat random strings with no prefix structure, and age says nothing about whether an image is still on a product page. **A lifecycle rule cannot express "delete what the database does not reference" and must not be used to try.** The diff has to be computed by the application.

Deletion itself has no server-side "delete the unreferenced" primitive either — the documented paths (<https://developers.cloudflare.com/r2/objects/delete-objects/>) are the dashboard, `wrangler r2 object delete <bucket>/<key>`, the Workers binding, and the S3 API, all requiring an explicit key or prefix.

No new dependency is needed for any of this: `aws-sdk-s3` is already in the Gemfile (`Gemfile:63`) and already configured as the `cloudflare` service (`config/storage.yml`). Do not add `wrangler`, a Cloudflare API token, or a Worker.

## Acceptance criteria

- [x] `Storage::BucketOrphanAudit` returns keys present in the bucket with no matching `active_storage_blobs.key`, with count and total bytes.
- [x] A key that does have a blob row is never reported.
- [x] The audit paginates — a bucket with more than one page of objects is fully covered, not just the first 1000 keys.
- [x] `bin/rails storage:audit_bucket_orphans` prints the report and deletes nothing.
- [x] `bin/rails storage:delete_bucket_orphans` refuses and exits non-zero when `config.x.storage.delete_files` is false.
- [x] It also refuses when `CONFIRM` is unset or not `yes`, even with the flag true.
- [x] With both satisfied, it deletes exactly the audited keys and logs each one.
- [x] Both tasks print the two-bullet explanation above — what gets reclaimed and what gets broken — before doing anything.

## Anchors

- `activestorage-8.1.3/lib/active_storage/service/s3_service.rb:15` — `attr_reader :client, :bucket`.
- `activestorage-8.1.3/lib/active_storage/service/s3_service.rb:63,69,75` — `delete(key)`, `delete_prefixed(prefix)`, `exist?(key)`. `delete_prefixed` shows how Rails itself batch-deletes through `bucket.objects(prefix:).batch_delete!`; it is prefix-scoped and so not usable for an arbitrary key list.
- `config/storage.yml` — the `cloudflare` service definition. All environments resolve to the same bucket by decision; do not write code that assumes otherwise.
- `lib/tasks/scheduler.rake` — the existing rake style to match. Put these in a **new** `lib/tasks/storage.rake`; they are operator-run and must not sit in the scheduler namespace, where they might get wired to a cron.
- R2 S3 API compatibility: <https://developers.cloudflare.com/r2/api/s3/api/> — R2 recommends `ListObjectsV2` over `ListObjects`.

## Failure and recovery

- The audit is read-only and safe to abort at any point.
- Listing a large bucket takes many paginated calls. Stream and count rather than materialising every `ObjectSummary`; hold only the key `Set` from the database (a few MB even at 100k blobs) and compare as you go.
- If the delete task fails partway, re-running the audit reflects the new state. No resume logic needed.
- Blobs uploaded *while* the audit runs will not have been in the initial key set. This is one more reason the delete task is confirmation-gated and not scheduled; note it in the task output.

## Non-goals

- Never schedule either task. Both are operator-run only, and `storage:delete_bucket_orphans` must never be added to `lib/tasks/scheduler.rake`.
- Do not add lifecycle rules from application code. If the user wants the incomplete-multipart-upload cleanup rule mentioned in the spec, it is a one-off `wrangler r2 bucket lifecycle add` performed outside the codebase.
- Do not delete the `active_storage_attachments` rows with `name: "images"` as part of this. The audit may show their blobs as stranded; reporting them is in scope, removing them is not (ticket 03).
- Do not extend the audit into a repair path. Finding a file with no row does not tell you what it was; there is nothing to restore it to.

## Focused verification

- `mise exec -- bin/rspec spec/models/storage/bucket_orphan_audit_spec.rb --format progress --color` — proves the diff, pagination, and that the audit deletes nothing. Specs run against the `:test` Disk service (`config/environments/test.rb:39`); write a stray file into `tmp/storage` with no blob row to produce an orphan. Never point a spec at R2.
- `mise exec -- bin/rails storage:audit_bucket_orphans` against the dev database, confirming it prints the warning and a report.
- `mise exec -- bin/rails storage:delete_bucket_orphans` against dev, confirming it refuses (dev has `delete_files` false) and exits non-zero.
