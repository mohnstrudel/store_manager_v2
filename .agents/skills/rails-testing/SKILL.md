---
name: rails-testing
description: Repository-specific Rails test boundaries, test infrastructure, verifying doubles, and shared behavioral contracts.
---

# Rails Testing

Use `collaborative-planning` for the process. Load this skill with the owning architecture skill when work touches the boundaries or infrastructure below.

## Boundaries

- Do not add controller specs. Request specs exercise real routing and own authorization, persistence, redirects, and the Rails-to-Inertia contract.
- `frontend-architecture`'s `testing.md` chooses component test versus Cuprite. Add Rails request coverage when the backend contract, authorization, persistence, or domain command changes.

## Test Infrastructure

- `sign_in(user)` signs in that user: request and controller specs receive a signed session cookie; Cuprite specs drive the sign-in form. Use `sign_in_as_admin` when the scenario requires an admin.
- `verify_partial_doubles` checks stubs on real objects; it does not verify plain `double` objects. Use `instance_double`, `class_double`, or `object_double` for stand-ins.

## Shared Contracts

- Use `shared_examples` only for a real semantic contract between independent producers, consumers, or interchangeable implementations.
- Duck Typer's RSpec integration is loaded globally. For classes sharing a role, default to `have_matching_interfaces`; the implicit public interface remains a living document.
- Use `methods:` when a class plays multiple roles. Use `namespace:` for a dedicated role namespace and an explicit list for a mixed namespace. Use `implement_canonical_interface` only when the design intentionally has a reference contract; define that contract with a small inline `Class.new`.
- Duck Typer does not verify parameter types, return values, or behavior. Pair structural interface checks with behavioral examples for every implementation.
