# Rails Jobs Architecture

Use this guide when the task is about Active Job, recurring work, async delivery, retries, queue design, or moving logic into or out of background jobs.

## Core Stance

- A job is usually a delivery shell, not the primary home of business logic.
- The domain method or subsystem object should usually own the real work.
- The job should add queue semantics:
- async execution
- retries
- discard policy
- batching
- checkpointing
- concurrency control

## Strong Patterns Worth Preserving

- Shared job infrastructure may set `enqueue_after_transaction_commit` centrally so model-triggered jobs are not enqueued before the database state is durable.
- Shared job infrastructure may serialize and restore tenant or account context for every job automatically.
- Recurring schedules may call domain class methods directly when that is clearer than creating a wrapper job.
- Domain objects may expose `*_later` methods so enqueueing remains part of the domain API.
- Long-running jobs may use checkpointed steps and logical cursors instead of one huge `perform`.

## 1. Keep Jobs Thin

- Good `perform` methods are usually one line:
- `notification.push`
- `bundle.deliver`
- `card.clean_inaccessible_data`
- `export.build`

- If `perform` grows long, first ask whether the logic belongs in:
- a model capability module
- a model-adjacent PORO under `app/models`
- a notifier or payload object
- a class method used by recurring schedules

## 2. Let Domain Objects Expose Async Entry Points

- Prefer small model methods such as:
- `process_later`
- `deliver_later`
- `build_later`
- `materialize_storage_later`

- This keeps enqueue behavior discoverable from the domain object itself.

## 3. Use Namespaced Jobs

- Put jobs under the same namespace as the domain they serve.
- Examples:
- `Card::CleanInaccessibleDataJob`
- `Event::WebhookDispatchJob`
- `Notification::Bundle::DeliverJob`
- `Storage::MaterializeJob`

- This keeps job ownership obvious and avoids a flat `app/jobs` junk drawer.

For external integrations:
- keep transport-facing jobs namespaced by the integration when that clarifies the queue boundary
- keep aggregate-owned mapping and reconciliation under the aggregate namespace

Example shape:
- `Shopify::PullProductJob` fetches and retries
- `Product::Shopify::Pull` parses and imports
- `Product::Shopify::MediaSync` reconciles media and store info

## 4. Prefer Coarse Operational Queues

- Queue names should describe operational behavior, not every feature.
- Good categories:
- `backend`
- `webhooks`
- `incineration`
- `default`

- Use separate queues when operators need different latency, retry, or isolation characteristics.

## 5. Default to Discarding Missing Records

- Many domain jobs can safely disappear if the target record no longer exists.
- `discard_on ActiveJob::DeserializationError` is often the right default for record-targeted jobs.
- Do not add recovery logic for a deleted record unless the product actually requires it.

## 6. Use Targeted Retry Policies

- Retry only the failures likely to recover.
- Examples:
- SMTP timeouts and temporary mailserver failures
- transient inability to get a stable reconciliation snapshot
- temporary network failures to external systems when the delivery object does not already handle them

- Do not retry corrupt files, permanent integrity failures, or bad inputs that will never succeed.

## 7. Use Job Concerns for Transport Policy

- If several jobs need the same retry or rescue behavior, extract a job concern.
- Good job-concern responsibilities:
- SMTP retry rules
- shared network error handling
- instrumentation
- narrow queue-specific policy

- Keep domain rules out of job concerns.

## 8. Use Checkpointed Jobs for Long Work

- When processing large imports, webhooks, or maintenance scans, prefer resumable jobs.
- `ActiveJob::Continuable` or a similar cursor/checkpoint mechanism is a strong fit.
- Save logical cursors such as:
- record ids
- file names
- step-local cursors

- This makes jobs restartable without redoing everything.

## 9. Use Concurrency Limits for Shared Aggregates

- If a job materializes a ledger, reconciles a snapshot, or mutates a shared derived value, overlapping runs can corrupt or thrash state.
- Use concurrency limits keyed to the actual owner or aggregate.
- Good examples:
- one materialization job per account
- one reconciliation job per board

## 10. Schedule Domain Entry Points, Not Script Blobs

- Recurring tasks should call:
- a focused job class
- or a small model class method

- Prefer schedule entries that read like business operations:
- `Card.auto_postpone_all_due`
- `Webhook::Delivery.cleanup`
- `Notification::Bundle.deliver_all_later`

- Avoid scheduler commands that hide the real behavior in unrelated scripts.
- If the work is a durable or failure-sensitive workflow, prefer scheduling a job.
- If the work is a simple, discoverable batch command on one subsystem, a model class method can be the better schedule target.

## 11. Rehydrate Request Context

- If your app depends on `Current.account`, `Current.user`, or similar request state, jobs must not assume it exists.
- Rehydrate context explicitly in one shared place or inside the called domain method.
- Context propagation belongs to infrastructure, not to every individual job body.
- If you already have a shared context-propagation mechanism, prefer using it over hand-setting `Current` inside each job.

## 12. Split Async Delivery Responsibilities

- Let the domain decide that something happened.
- Let notifier or payload objects decide:
- recipients
- payload structure
- product-specific branching

- Let the job do async execution.
- Let the mailer or renderer do final formatting.

This separation keeps jobs thin and domain behavior testable.

The same split applies to pull and sync jobs:
- let the job own transport timing
- let model-area integration objects own parsing, import, reconciliation, and aggregate-specific cleanup
- let tiny relation-shape helpers become scopes instead of standalone query classes when they have no identity of their own

## 13. When Not To Add A Job

- Do not add a job just to avoid calling `deliver_later` on a mailer.
- Do not add a job when the work is fast, local, and must happen in the same transaction.
- Do not create wrapper jobs that exist only to call one service object whose only purpose is to hide the same domain method.

## 14. Anti-Default LLM Checklist

- Do not turn every background action into a service-object pipeline.
- Do not put business branching into jobs if the target model or subsystem already owns the concept.
- Do not ignore resumability for long-running batch work.
- Do not ignore concurrency control for jobs touching ledgers or derived totals.
- Do not build one queue per feature unless operations truly need that split.
- Do not forget that recurring schedules can call model class methods directly when that is the clearest expression.
- Do not keep aggregate-specific sync and cleanup steps in a job just because the job fetched the external payload first.
