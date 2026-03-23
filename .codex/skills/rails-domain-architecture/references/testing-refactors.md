# Testing Refactors

Use this guide when refactoring tests alongside architecture changes or when a legacy Rails suite no longer matches the ownership seams in the code.

## Core Read

- Tests should move with ownership.
- Do not preserve old test placement just because it mirrors a legacy service or controller that you are refactoring away.
- Pick the test seam that matches the refactored code, not the old class name.

## Default Rule For Legacy Test Refactors

- When logic moves under `app/models/<model>/`, move or add tests under the matching model namespace.
- When request behavior is the contract, prefer request or integration tests.
- When rendering is the contract, test HTML, JSON, and Turbo at the edge.

## 1. Default File Targets

Model capability tests:
- `test/models/product/editions_test.rb`
- `spec/models/product/editions_spec.rb`
- `test/models/sale/linking_test.rb`
- `spec/models/sale/linking_spec.rb`

Request/controller tests:
- `test/controllers/products_controller_test.rb`
- `spec/requests/products_spec.rb`
- `test/controllers/concerns/current_timezone_test.rb`
- `spec/requests/public/products_spec.rb`

Jobs:
- `test/jobs/product/pull_from_shop_job_test.rb`
- `spec/jobs/product/pull_from_shop_job_spec.rb`

Presentation:
- `test/helpers/products_helper_test.rb`
- `spec/helpers/products_helper_spec.rb`
- `test/system/product_flow_test.rb`
- `spec/features/product_flow_spec.rb`

## 2. What To Move With The Refactor

- If a service becomes `Product::Editions`, move the core behavior tests to the product capability seam.
- If a controller transaction becomes `Sale::Creation`, keep request tests for the endpoint and add or move behavior tests to the model-area workflow object.
- If JSON or Turbo rendering becomes explicit templates, add edge-format assertions there instead of asserting controller internals.

## 3. Preserve The Right Kinds Of Tests

- preserve request boundary tests
- preserve negative-path tests
- preserve time-dependent domain rules
- preserve async outcome tests

- Do not preserve brittle tests that only mirror private implementation.

## 4. Factories, Fixtures, and Helpers

- Keep domain scenarios stable across the refactor.
- Update factories or fixtures so they still represent:
- access boundaries
- lifecycle states
- matching/linking cases
- integration ids and timestamps when relevant

- Move helper support code only when the seam changes.

## 5. What Not To Preserve

- Do not preserve a `spec/services/...` test just because a legacy service file used to exist.
- Do not preserve controller-unit style tests if the endpoint is better expressed by request coverage.
- Do not preserve feature tests that only duplicate cheaper integration coverage.

## 6. Anti-Default LLM Checklist

- Do not leave tests behind at the old seam after moving ownership.
- Do not invent new service specs for logic that now belongs to a model capability.
- Do not refactor code without also proposing the new test file destinations.
