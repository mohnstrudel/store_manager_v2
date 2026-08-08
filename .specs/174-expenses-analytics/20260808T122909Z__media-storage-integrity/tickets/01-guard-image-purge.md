# 01. Stop every code path from deleting R2 files synchronously

Spec: ../spec.md
Status: done
Blocked by: none

## What to build

Three code paths delete files from the shared R2 bucket immediately and in every environment. Every environment points at the same bucket, and local and staging run on a hand-copied production database backup — so their `Media` rows carry **production's own blob keys**, and a delete performed there deletes the file production is serving.

This is the confirmed cause, not a precaution. Restore the production backup into staging, re-pull products from Shopify, and `remove_obsolete_shopify_media` destroys every `Media` whose stored checksum does not match the fresh download. Each destroy purges a production key. Production's row survives, dangling, and its image 404s. **This ticket is the urgent one in the spec** — until it ships, one routine staging re-pull can take out production images.

Close all three, and introduce the single flag that decides whether an environment may delete files at all. Actual deletion moves to the scheduled, production-gated reclamation job in ticket 04 — this ticket removes the synchronous deletes and does **not** add a replacement purge callback.

### 1. Add the policy flag

```ruby
# config/environments/production.rb, config/environments/test.rb
config.x.storage.delete_files = true

# config/environments/development.rb, config/environments/staging.rb
config.x.storage.delete_files = false
```

Set it explicitly in all four. An unset `config.x` value reads as `nil`, so "do not delete" is the failure default. Tickets 04 and 05 read this same flag; do not introduce a second one.

### 2. Turn off automatic purging on `Media#image`

```ruby
has_one_attached :image, dependent: false do |attachable|
  ... # variant block unchanged
end
```

**Pass `dependent: false` explicitly. Do not simply drop the `dependent:` keyword** — in `activestorage-8.1.3` the parameter defaults to `:purge_later` (`lib/active_storage/attached/model.rb:108`), so omitting it changes nothing at all.

This covers both triggers at once, which is why no callback is needed. Purging is fired by `ActiveStorage::Attachment`'s `after_destroy_commit :purge_dependent_blob_later` (`app/models/active_storage/attachment.rb:37`), reading the `dependent` option off the reflection at destroy time (`attachment.rb:150-155`). The attachment row is destroyed both when the `Media` record is destroyed **and** when its image is replaced — so a record-level `before_destroy` callback would miss replacement entirely, which is the more frequent case here (`app/models/media/form_handling.rb:47`).

### 3. Delete the explicit purge in `Upsert#attach_image`

```ruby
def attach_image(media, downloaded_file)
  media.image.purge if media.image.attached?   # <- delete this line
  media.image.attach(...)
end
```

`attach` already replaces the attachment. The `.purge` adds nothing but an ungated, immediate file delete that step 2 cannot gate, because it is a direct call rather than the `dependent:` mechanism.

### Where the files actually go

After this ticket, a destroyed or replaced `Media` image leaves its blob with no attachment rows — it lands in `ActiveStorage::Blob.unattached` (`activestorage-8.1.3/app/models/active_storage/blob.rb:46`). Ticket 04 purges those on a schedule, in permitted environments only. Until ticket 04 ships, production reclaims nothing; that is expected and is why the two tickets belong to one slice.

## Acceptance criteria

- [x] `config.x.storage.delete_files` is set explicitly in `production.rb`, `staging.rb`, `development.rb`, and `test.rb`.
- [x] Destroying a `Media` removes the `Media` row and its `ActiveStorage::Attachment` row, enqueues no `ActiveStorage::PurgeJob`, and leaves the file in storage.
- [x] After that destroy, the blob is returned by `ActiveStorage::Blob.unattached`.
- [x] Replacing a `Media`'s image (attaching a second file over the first) leaves the previous file in storage and enqueues no `ActiveStorage::PurgeJob`.
- [x] `Product::Shopify::Media::Upsert` re-attaching over an existing image does not delete the previous file from the service.
- [x] No behaviour change to which rows are destroyed — only to whether the underlying file is deleted.

## Anchors

- `app/models/media.rb:20` — `has_one_attached :image, dependent: :purge_later do |attachable| ... end`. Change `dependent:` to `false`; keep the variant block byte-for-byte.
- `app/models/product/shopify/media/upsert.rb:50` — the `media.image.purge if media.image.attached?` line to remove.
- `spec/models/media_spec.rb:22-25` — the existing example `"has_one_attached image with dependent: :purge_later"` under `describe "associations"` asserts only that the image is present. Replace it with the destroy and replacement examples above.
- `config/environments/staging.rb:43`, `production.rb:46`, `development.rb:60` — where `config.active_storage.service = :cloudflare` is set; put the new flag beside it so the bucket policy and the deletion policy read together.

## Non-goals

- Do not add a `before_destroy` or `after_destroy_commit` purge callback on `Media`. Deletion is ticket 04's job. A `before_destroy` purge in particular would delete the file ahead of commit, so a rolled-back destroy would leave a live row pointing at a deleted file — the exact bug this spec exists to fix.
- The legacy `HasPreviewImages` attachment is ticket 03's (removed, not gated). Do not touch it here.
- Do not change `Product::Shopify::MediaImporting`, or anything in `Upsert` beyond deleting that one purge line.
- `ActiveStorage::VariantRecord` keeps ActiveStorage's `:purge_later` default; it is not ours to configure and ticket 02 relies on that cascade.

## Focused verification

- `mise exec -- bin/rspec spec/models/media_spec.rb spec/models/product/shopify/media/upsert_spec.rb --format progress --color` — proves nothing is deleted on destroy or replacement, and that the rest of `Media` and `Upsert` behaviour is unaffected.
