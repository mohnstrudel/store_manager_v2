# Codex Rails Jobs Guide

Use this document as a reusable job architecture brief for Codex on other Rails projects. It captures a job style where jobs are thin wrappers around domain methods, scheduling is explicit, and reliability choices are deliberate.

## AGENTS.md Snippet

```md
# Rails Jobs

Design jobs as transport and orchestration shells around domain methods, not as the main home of business logic.

- Keep job classes thin. A job should usually call one model method, subsystem method, or mailer entry point.
- Put business rules in models or model-adjacent objects, then expose small enqueue entry points such as `process_later`, `deliver_later`, or `materialize_storage_later`.
- Namespace jobs by domain under `app/jobs/<namespace>/`.
- Use coarse queue names by operational concern such as `backend`, `webhooks`, or `incineration`, not one queue per feature unless operations demand it.
- Prefer a shared infrastructure hook that enqueues jobs only after transaction commit if your app frequently enqueues from model callbacks or commands.
- Default to `discard_on ActiveJob::DeserializationError` for jobs whose target record can disappear safely.
- Add targeted `retry_on` only for transient failures you expect to recover from.
- Use resumable or checkpointed jobs for long-running batch workflows.
- Use concurrency limits when the job materializes, reconciles, or mutates a shared aggregate or ledger and overlapping runs would conflict.
- Propagate request or tenant context into jobs explicitly, or use one shared mechanism that rehydrates `Current` safely before `perform`.
- Let recurring schedules call a small model class method or a focused job, whichever keeps the behavior most discoverable.
- Prefer `after_commit` or equivalent post-transaction hooks when enqueueing jobs from model changes.
- Keep delivery jobs thin: payload construction, recipient selection, and product rules should usually live in model-adjacent collaborators.
```

## Core Rules

- A job is usually a wrapper, not a subsystem.
- If the job body grows large, first ask whether that logic belongs in:
  - a model capability
  - a query or workflow object under `app/models`
  - a notifier or payload object
  - a domain class method used by recurring schedules

- Only keep substantial logic in the job when the logic is genuinely about:
  - checkpointing
  - retries
  - concurrency control
  - batching
  - transport semantics

## Strong Patterns Worth Copying

- Add a shared job-layer mechanism for tenant or account context propagation so individual jobs stay small.
- Set enqueue-after-commit behavior centrally when your app commonly enqueues from model callbacks or domain commands.
- Let models expose `*_later` methods so enqueue behavior stays part of the domain API.
- Use domain class methods as scheduler entry points for simple recurring work instead of hiding everything behind separate service wrappers.
- Keep long-running jobs resumable with checkpoints instead of accepting large all-or-nothing runs.
- Use job concerns only for transport policy such as retry logic, not for business rules.

## Good Job Shapes

Simple wrapper job:

```ruby
class Notification::PushJob < ApplicationJob
  discard_on ActiveJob::DeserializationError

  def perform(notification)
    notification.push
  end
end
```

Queued subsystem entry point:

```ruby
class DataExportJob < ApplicationJob
  queue_as :backend
  discard_on ActiveJob::DeserializationError

  def perform(export)
    export.build
  end
end
```

Checkpointed batch workflow:

```ruby
class Account::DataImportJob < ApplicationJob
  include ActiveJob::Continuable
  queue_as :backend

  def perform(import)
    step :check do |step|
      import.check(start: step.cursor, callback: ->(record_set:, file:) { step.set!([record_set.model.name, file]) })
    end

    step :process do |step|
      import.process(start: step.cursor, callback: ->(record_set:, files:) { step.set!([record_set.model.name, files.last]) })
    end
  end
end
```

Serialized maintenance job:

```ruby
class Storage::MaterializeJob < ApplicationJob
  queue_as :backend
  limits_concurrency to: 1, key: ->(owner) { owner }
  discard_on ActiveJob::DeserializationError

  def perform(owner)
    owner.materialize_storage
  end
end
```

## When To Use A Job

Use a job when you need:
- async delivery after commit
- retry semantics
- queue isolation
- resumability for long work
- concurrency control
- out-of-band execution for expensive side effects

Do not add a job just to hide a method call. If `Mailer.deliver_later` is sufficient, use it.

## Scheduling Rules

- Prefer recurring schedules that call small, explicit model class methods or focused jobs.
- Good schedule entry points:
- `Card.auto_postpone_all_due`
- `Webhook::Delivery.cleanup`
- `Notification::Bundle.deliver_all_later`
- `Account::IncinerateDueJob`

- The scheduled entry point should be obvious and easy to find from the domain object.
- If the scheduled work is a simple batch cleanup or batch command, a model class method may be clearer than creating an extra wrapper job.
- If the scheduled work needs queue choice, retries, checkpointing, or concurrency control, schedule a focused job instead.

## Retry and Discard Rules

- Use `discard_on ActiveJob::DeserializationError` when the work is irrelevant if the record was deleted.
- Use custom `discard_on` for permanent domain failures such as corrupt import files or integrity errors.
- Use `retry_on` for genuinely transient failures such as SMTP timeouts, temporary mailserver failures, or unstable snapshot windows.
- Keep retry policy near the transport concern, often via a small job concern.

## Context Rules

- If domain behavior depends on tenant or account context, make sure the job rehydrates that context before `perform`.
- Prefer one shared mechanism in `ApplicationJob` or an initializer over reimplementing context restoration in every job.
- If a model method already manages its own context safely, the job can stay thin and call that method.
- Also apply this to Action Cable delivery, mailers, and renderer usage so background behavior matches request behavior.

## Queue Rules

- Group queues by operational behavior rather than by tiny domain slices.
- Example queue categories:
- `backend` for durable background work
- `webhooks` for external HTTP delivery
- `incineration` for destructive lifecycle work

- Keep queue names meaningful to operators.

## Concurrency Rules

- Use concurrency limits when overlapping runs would:
- double-apply ledger entries
- race on a materialized snapshot
- produce conflicting aggregate state

- Key the limit to the actual shared owner or aggregate, not to a broad class if finer locking is possible.

## Anti-Default LLM Checklist

- Do not move domain workflow out of the model layer just because a job exists.
- Do not create a service object for every job target; the target method may already be the right abstraction.
- Do not put payload generation, recipient selection, or business branching into the job unless it is truly transport-specific.
- Do not schedule giant scripts when a model class method expresses the intent more clearly.
- Do not ignore concurrency and resumability for long-running maintenance or import/export jobs.
- Do not overfit retry logic; retry only the failures that are likely to recover.
