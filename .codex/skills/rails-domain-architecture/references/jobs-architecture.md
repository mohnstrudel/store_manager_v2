# Rails Jobs Architecture

Use this file for the non-obvious async and job ownership rules in this repo.

## Core Rules

- A job is usually a transport shell.
- The domain object should usually own the real workflow.
- Keep in the job:
  - queue choice
  - retry or discard policy
  - checkpointing
  - concurrency control
  - calling one domain entry point
- Move out of the job:
  - recipient selection
  - payload building
  - aggregate state transitions
  - reconciliation rules
  - aggregate-local orchestration
- Prefer one clear model-facing entry point such as `sync_now`, `relay_now`, or another domain verb over a job plus wrapper service plus model.

## Placement Decisions

- thin job -> `app/jobs/<namespace>/<action>_job.rb`
- aggregate-local workflow -> `app/models/<model>/<workflow>.rb`
- integration-specific import or reconciliation -> `app/models/<model>/<integration>/...`
- shared transport policy -> `app/jobs/concerns/<policy>.rb`

## Repo-Specific Bias

- Prefer model-area collaborators over generic services when the job supports one aggregate.
- For Shopify work, keep transport-facing jobs under the integration namespace and aggregate-specific parsing or reconciliation under the aggregate namespace.
- Use `*_later` and `*_now` pairs when the async and sync entry points represent the same domain action cleanly.

## What Codex Often Gets Wrong

- Do not solve a fat job by adding another wrapper service without changing ownership.
- Do not keep aggregate-specific sync and cleanup steps in the job just because the job fetched the payload.
- Do not create wrapper jobs that only hide one domain method.
- Do not invent a service layer between the job and the aggregate when the job can call the owning model directly.
- Do not build one queue per feature unless operations truly need it.

## Strong Patterns Worth Preserving

- `*_later` entry points on domain objects
- recurring schedules that call a small model class method when that is the clearest boundary
- shared context propagation in one place instead of per-job `Current` setup
- checkpointed jobs for long-running imports or reconciliations
