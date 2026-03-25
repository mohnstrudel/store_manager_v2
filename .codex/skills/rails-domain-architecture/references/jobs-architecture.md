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

## Placement Decisions

- thin job -> `app/jobs/<namespace>/<action>_job.rb`
- aggregate-local workflow -> `app/models/<model>/<workflow>.rb`
- integration-specific import or reconciliation -> `app/models/<model>/<integration>/...`
- shared transport policy -> `app/jobs/concerns/<policy>.rb`

## Repo-Specific Bias

- Prefer model-area collaborators over generic services when the job supports one aggregate.
- For Shopify work, keep transport-facing jobs under the integration namespace and aggregate-specific parsing or reconciliation under the aggregate namespace.

## What Codex Often Gets Wrong

- Do not solve a fat job by adding another wrapper service without changing ownership.
- Do not keep aggregate-specific sync and cleanup steps in the job just because the job fetched the payload.
- Do not create wrapper jobs that only hide one domain method.
- Do not build one queue per feature unless operations truly need it.

## Strong Patterns Worth Preserving

- `*_later` entry points on domain objects
- recurring schedules that call a small model class method when that is the clearest boundary
- shared context propagation in one place instead of per-job `Current` setup
- checkpointed jobs for long-running imports or reconciliations
