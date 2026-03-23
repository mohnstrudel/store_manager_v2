# Rails Domain Architecture Refactor Playbook

## Decision Matrix

| If you are adding or moving... | Put it in... | Why |
| --- | --- | --- |
| A single-model business capability with related associations, scopes, and commands | `app/models/<model>/<capability>.rb` | Keep reads and writes for one concept together |
| Generic reusable behavior used by multiple models | `app/models/concerns/<concern>.rb` | Keep cross-cutting templates separate from model-specific logic |
| A persisted filter, search subsystem, report builder, or adapter-specific query backend | `app/models/<subsystem>/` and a coordinating model object | Give the subsystem its own place without inventing a generic service layer |
| A workflow object centered on one aggregate and its child records | `app/models/<model>/<workflow>.rb` or `app/models/<namespace>/<workflow>.rb` | Keep aggregate-local orchestration near the concept instead of defaulting to `app/services` |
| Multi-aggregate orchestration or external IO | A focused service object | Keep orchestration separate from one model's invariant |
| Repeated preload or ordering shape | A named scope on the owning relation | Make repeated reads explicit and composable |
| Authorization or tenancy entry point | An association on the user, account, or parent record | Start queries from the real boundary |

## Use This Sequence for New Features

1. Identify the model that owns the invariant.
2. Identify the access boundary that should start the relation.
3. Decide whether the work is a capability, a cross-cutting concern, a first-class query subsystem, or orchestration.
4. Create or extend a capability module if the feature belongs to one model.
5. Add small named scopes instead of a mega-query.
6. Add a preload scope if the feature introduces a repeated read shape.
7. Keep the controller responsible only for loading the relation and invoking commands.

## Use This Sequence for Refactors

1. Find controllers or services that build long relations against one model.
2. Identify the real request boundary: account, user, parent resource, or public access.
3. Group clauses by business concept instead of by SQL operation.
4. Move each group into a named scope on the owning model or capability module.
5. Move related callbacks, predicates, and commands into the same capability module.
6. Replace controller SQL with relation composition from the correct boundary relation.
7. Move presentation branching into helpers, partials, or serializers if it leaked into models or controllers.
8. Move side-effect dispatch into thin jobs if controllers or models are doing delivery inline.
9. Introduce a first-class query object only if the query has parameters, persistence, caching, multiple backends, or a user-facing identity.
10. Realign the tests with the new ownership seam: capability tests for model concepts, integration tests for request flow, and focused edge-format assertions for HTML, JSON, or Turbo.
11. Stop refactoring once the design becomes easier to navigate; do not chase purity at the expense of the current codebase.

When refactoring a legacy app:
- do not treat current controller or service placement as a convention worth preserving by default
- propose explicit target files under `app/models/<model>/...`
- move one coherent slice at a time instead of rewriting the whole aggregate

## Smells That Usually Mean "Extract a Capability Module"

- One part of a model owns several associations and several related scopes.
- Instance methods and scopes talk about the same business concept but live far apart.
- A model file is large because it contains many distinct concepts, not because one concept is deep.
- A controller or service calls several methods that all revolve around the same model state.
- A method is long because it is enumerating a real domain matrix, and the logic would become less obvious if abstracted further.

## Smells That Usually Mean "Create a Query Subsystem"

- The query has saved parameters or a persisted identity.
- The query needs normalization, digesting, caching, or summaries.
- The query supports multiple backends or adapter-specific implementations.
- The query is a user-facing concept such as a saved filter or a search history item.
- The query is doing more than exposing a reusable preload shape or a simple named relation.

## Smells That Usually Mean "Keep the Service Object"

- The operation spans several models that do not have one obvious owner.
- The operation coordinates external APIs, email, files, or background jobs.
- The operation is mostly workflow orchestration rather than domain state on one aggregate.

## Smells That Usually Mean "Move This Service Under A Model Namespace"

- The service is centered on one aggregate plus its children.
- The service mostly loads local records and applies matching or transition rules.
- The service name sounds like a business workflow, not an infrastructure boundary.
- The controller, model, and service all share the same domain vocabulary and the service adds no new boundary of its own.
- Several importer, parser, or export files clearly belong to one aggregate and one external system but are scattered or flatly named.

## Smells That Usually Mean "Move This Out of the Controller"

- The action builds a long relation chain with several joins and conditionals.
- The action decides recipients, payload text, or notification routing.
- The action branches heavily by business state instead of request format.
- The action contains reusable rendering-shape loading such as repeated `includes` or `preload` sets.

## Smells That Usually Mean "Move This Out of the Model"

- The method mostly returns HTML, CSS classes, or route-linked button labels.
- The logic is only needed by one screen or one response format.
- The method hand-builds JSON or response hashes better expressed by a template or serializer.

## Smells That Usually Mean "Use a Controller Concern"

- Several controllers repeat the same scoping or guard logic.
- Several controllers need the same request-context setup.
- The extracted concern would load records or apply policy, not own business invariants.

## Smells That Usually Mean "Your Tests Are Pointing At The Right Model Boundary"

- One capability can be tested with a small amount of setup and a few public commands.
- The same state is visible through scopes, predicates, and commands on one object.
- Negative-path behavior such as draft suppression or access-loss cleanup is easiest to express at the model seam.
- Time-based behavior is easiest to test by freezing time around one domain object instead of around a scheduler script.

## Review Checklist

- Is the starting relation already authorization- or tenancy-scoped?
- Is request context established in one obvious place?
- Do scope names reflect business language?
- Does each scope remain composable?
- Are repeated preload sets named?
- Does the capability module own both the read-side and write-side API for its concept?
- Did we preserve readable core loops where the domain itself is combinatorial, instead of abstracting them into something harder to scan?
- Did we keep importer and parser steps readable, instead of hiding a straightforward integration flow behind a generic abstraction?
- Are controllers loading, delegating, and rendering rather than owning business rules?
- Are presentation decisions living in helpers, partials, or serializers?
- Are jobs thin wrappers instead of the home of business workflow?
- Is a new service or query object justified by subsystem complexity rather than discomfort with a longer model?
- Did we choose explicit target files under `app/models/<model>/...` for aggregate-local logic instead of leaving the refactor destination vague?
- For model-owned integrations, did we separate low-level transport from aggregate-specific mapping and use clear names such as `Parser`, `Importer`, `Payload`, or `Exporter`?
- Do the tests still line up with the ownership seam after the refactor?
- Did the refactor preserve the existing project's conventions where they are already coherent?
