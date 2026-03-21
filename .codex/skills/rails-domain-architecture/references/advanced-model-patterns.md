# Advanced Model Patterns

Use this guide for model-centric Rails codebases that look "wrong" to generic service-object advice but are actually well-structured.

## 1. A Model Can Be an Assembly Point, Not a Dumping Ground

- A large domain model does not have to mean one giant file.
- The base model can stay small while assembling many capability modules.
- Think of the base model as the aggregate's table of contents.

## 2. Capability Modules Can Own a Whole Slice

- A capability module may own all of these together:
- associations
- scopes
- callbacks
- predicates
- commands
- small private helpers

- This is often better than splitting one business concept across:
- model
- service
- query object
- policy
- presenter

## 3. Cross-Cutting Concerns Can Be Mini-Frameworks

- Some concerns are really reusable internal frameworks.
- They define hooks and contracts that model-specific modules satisfy.

Typical shape:

```ruby
module Searchable
  extend ActiveSupport::Concern

  included do
    after_create_commit :create_in_index
  end

  private
    # including model must implement:
    # - search_title
    # - search_content
    # - searchable?
end
```

- This is a strong pattern when the concern expresses one repeated system behavior.
- Do not flatten these concerns into “helper methods” if they are doing real architectural work.

## 4. Association Proxies Can Be Real APIs

- Rails association extensions are underused.
- They are useful when a collection has behavior that belongs to the relationship itself.

Good examples:
- granting and revoking board access
- revising membership sets
- batch commands on child rows tied to one parent

- Prefer this when:
- the logic is tightly coupled to one parent-child collection
- the collection itself has a domain verb
- a standalone service would only wrap one association

## 5. Capability Modules Can Collaborate Through the Aggregate

- One capability module may call methods defined in another module on the same model.
- That is acceptable when both modules belong to the same aggregate and communicate through a small, coherent API.

Examples:
- postponing may call reopening or triage-reset methods
- accessibility cleanup may call watcher or pin logic
- event modules may call comment or notification helpers

- Do not split these interactions into services just to avoid module-to-module calls.

## 5.5. Keep Readable Domain Loops Readable

- Some long methods are long because the domain itself is enumerating a real matrix or sequence.
- Examples:
- generating edition combinations
- scanning eligible records in order
- matching child records against available inventory

- In those cases:
- move the method into the correct capability module
- extract the rule names and predicates
- keep the central loop obvious

- Do not force a readable nested loop into a more abstract iterator pipeline if that makes the rule harder to scan at a glance.

## 6. Event Fan-Out Can Be Centralized

- A good way to avoid callback chaos is to centralize fan-out around a domain event.
- The event becomes the durable source for:
- timelines
- notifications
- webhooks
- system comments
- push payloads

- This is different from “fat callback soup.”
- The event model creates a single language for downstream behavior.

## 7. Callbacks Are Fine When They Stay Local

- Generic advice often says to avoid callbacks.
- A better rule is: avoid surprising callbacks.

Good callback uses:
- maintain adjacent read models
- enqueue a job
- write to a ledger
- create a domain event
- refresh a broadcast target

Bad callback uses:
- hidden multi-system workflows
- business-critical branches spread across many unrelated models
- sequences that only work because of fragile ordering

## 8. Not All Representation Logic Is View Logic

- Screen-specific markup belongs in views and helpers.
- But some representations are domain interfaces, not page rendering.

Good candidates for model-adjacent representation objects:
- export JSON or HTML
- webhook payloads
- notification payloads
- AI prompt text
- event descriptions reused across channels

- Keep these near the domain because they encode business meaning for integrations, exports, and automation.
- This is the main reason not to introduce presenters by default: some string-building belongs at the edge, but some belongs near the domain.

## 9. Technical Systems Can Be Product Abstractions

- Some infrastructure-heavy areas are still domain concerns because users feel them directly.
- Examples:
- storage quotas
- notification bundles
- import/export manifests
- search indexing

- Model these explicitly in the domain layer, even if the implementation touches Active Storage, background jobs, HTTP clients, or external storage.
- It is okay if the domain abstraction intentionally differs from physical infrastructure reality, as long as that rule is explicit.

## 10. Extensibility Can Live in the Model Layer

- Plugin-style registration and namespaced dispatch can be valid model patterns.
- Examples:
- registering push targets
- mapping event types to notifier classes
- adapter-specific backend lookup

- Use this sparingly.
- Keep the dispatch table obvious and constrained.
- Prefer explicit namespaced classes over generic magic.

## 11. Persisted UI State Can Still Be Domain State

- Saved filters, search history, notification settings, and other user-configured state often sit between “UI” and “domain.”
- Treat them as first-class domain objects when they:
- persist
- drive queries
- affect notifications or automation
- appear in multiple parts of the product

- Do not dismiss them as “just presentation.”

## 12. Lifecycle States Can Gate Downstream Systems

- Some model states are not just display flags.
- They can intentionally block downstream behavior such as:
- mention creation
- search indexing
- notification fan-out
- push delivery
- email delivery

- Examples include:
- drafted vs published
- active vs inactive
- accessible vs inaccessible
- cancelled vs active accounts

- Keep these gates near the owning state transition or capability.
- Do not scatter them across controllers, jobs, and services.

## 13. Access Loss Can Be a Domain Cleanup Boundary

- Losing access is often a real domain transition, not just an authorization detail.
- It may need to clean up:
- mentions
- notifications
- watches
- pins
- cached or materialized visibility state

- A focused cleanup job or capability method is a valid design when the cleanup belongs to that access boundary.
- Do not assume every cleanup is “background infrastructure”; it may be a product rule.

## 14. Temporal Rules Belong in Domain Objects

- If users experience a time-based rule as product behavior, it belongs in the domain layer.
- Examples:
- bundle windows
- inactivity thresholds
- due-ness
- last activity timestamps
- expiration and freshness rules

- The scheduler may trigger the work, but the rule itself should usually live in the model or model-adjacent object.
- This makes the behavior easier to test and easier to reuse.

## 15. Public APIs May Have Both Immediate and Async Faces

- A good domain object may expose both:
- an immediate command such as `deliver`, `build`, or `materialize_storage`
- an async entry point such as `deliver_later`, `build_later`, or `materialize_storage_later`

- This keeps transport decisions close to the concept instead of creating a second abstraction layer just for enqueueing.
- It also makes the model easier to schedule, test, and reuse.

## 16. What Not To Refactor Away

Do not automatically replace these with services:
- capability modules that own a coherent slice
- concern contracts with clear hooks
- association-proxy APIs
- event-driven fan-out
- lifecycle gates that suppress downstream behavior
- access-loss cleanup owned by a domain boundary
- temporal rules on domain objects
- payload builders and export objects in model namespaces
- class-level cleanup or scheduler entry points on model subsystems

Refactor only when the current pattern is no longer coherent, discoverable, or bounded.
