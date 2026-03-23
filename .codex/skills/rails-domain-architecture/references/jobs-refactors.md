# Jobs Refactors

Use this guide when refactoring legacy Rails jobs that currently contain business branching, service pipelines, or scheduler glue that hides domain ownership.

## Core Read

- Jobs should usually be transport shells.
- Do not treat the current fat job body as the target architecture.
- Treat job code as evidence for which domain object really owns the workflow.

## Default Rule For Legacy Jobs

- Keep in the job:
- queue choice
- retry or discard policy
- checkpointing
- concurrency control
- calling one domain method

- Move out of the job:
- recipient selection
- payload building
- aggregate state transitions
- matching rules
- local orchestration that belongs to one aggregate

## 1. Default File Targets

Thin jobs:
- `app/jobs/<namespace>/<action>_job.rb`
- `app/jobs/product/pull_from_shop_job.rb`
- `app/jobs/sale/push_update_job.rb`
- `app/jobs/purchase_item/notify_job.rb`

Aggregate-local workflow:
- `app/models/product/shop_sync.rb`
- `app/models/sale/shop_sync.rb`
- `app/models/purchase_item/notifier.rb`
- `app/models/warehouse/relocation.rb`
- `app/models/notification/bundle.rb`

Job transport policy:
- `app/jobs/concerns/<policy>.rb`

Recurring entry points:
- `config/recurring.yml`
- model class methods such as `Sale.pull_due` or `Notification::Bundle.deliver_all_later`

## 2. When To Move Logic Out Of A Job

- when `perform` knows too much about business states
- when the job chooses recipients or payloads
- when several jobs duplicate the same workflow rules
- when a job exists only to call one service that only wraps one aggregate method

## 3. When A Service Should Move Out Of `app/services`

- If it is only supporting one job and one aggregate, consider moving it to:
- `app/models/<model>/<workflow>.rb`
- or `app/models/<namespace>/<workflow>.rb`

- Good examples:
- sync coordinators
- notifier objects
- relocation workflows
- import step coordinators anchored to one model area

## 4. Refactor Patterns

### Fat Delivery Job

- Move recipient and payload logic into a notifier or payload object.
- Keep the job responsible for async transport only.

### Fat Sync Job

- Move domain mapping and persistence rules into `Product::ShopifyImporter`, `Sale::ShopSync`, or another model-area collaborator.
- Let the job call one entry point.

### Integration Pull Job

- If a job fetches one remote payload and then parses, imports, cleans up local records, or schedules follow-up sync work, the job is often sitting on top of a model-owned integration slice.
- Keep in the job:
- queue choice
- retry policy
- maybe the remote fetch if that is the clearest transport boundary
- calling one aggregate-owned entry point

- Move out of the job:
- payload parsing
- local record cleanup
- media or edition reconciliation
- aggregate-specific branching after fetch

- Good target shapes:
- `app/models/product/shopify/pull.rb`
- `app/models/product/shopify/importer.rb`
- `app/models/product/shopify/media_sync.rb`
- `app/models/sale/shopify/pull.rb`

- Example direction:
- a `PullProductJob` can stay thin if it fetches the payload and calls `Product::Shopify::Pull.import!(payload)`
- a `PullMediaJob` should usually not own download, checksum reconciliation, obsolete-media cleanup, and store-info syncing inline; that work usually belongs in something like `Product::Shopify::MediaSync`
- a tiny preload helper used only by that sync path is usually better as a named scope such as `Product.for_media_sync`

### Transport Base Job

- A base job class can be a good home for transport-only mechanics shared across one integration.
- Good examples:
- pagination cursors
- rate-limit backoff
- shared API error handling
- re-enqueueing the next page

- Keep business parsing and importing out of the base job.
- A good base job should feel like infrastructure, not like a hidden workflow manager.

### Recurring Cleanup Job

- If the work is a simple batch command on one subsystem, schedule a model class method instead of hiding the behavior behind a vague job wrapper.

## 5. What Not To Preserve

- Do not preserve service pipelines just because the scheduler currently calls them.
- Do not preserve giant `perform` methods when they are mostly domain branching.
- Do not preserve one queue per tiny feature when broad operational queues are clearer.

## 6. Anti-Default LLM Checklist

- Do not solve a fat job by adding another wrapper service without changing ownership.
- Do not leave enqueue entry points disconnected from the domain when `*_later` on the model would be clearer.
- Do not keep recurring work in opaque scripts if a model class method expresses the intent better.
- Do not leave model-owned sync and reconciliation code in jobs just because the remote system is external.
- Do not move pagination or retry policy into a domain object when it is really transport infrastructure.
