---
name: shopify
description: Use for Shopify Admin API work in this repo. The important local rule is that GraphQL calls go through shared Shopify model-layer objects, with sync logic kept in jobs and parser or serializer layers.
---

# Shopify

- Use this skill together with `rails-domain-architecture` when the task also changes model placement, controllers, views, jobs, or tests.
- Keep the Shopify transport client, GraphQL queries, and mutations in explicit Shopify namespaces under `app/models`.
- Keep aggregate-specific importers, parsers, payloads, and exporters in the owning model namespace such as `app/models/product/shopify/`.
- Sync orchestration lives in [app/jobs/shopify](/Users/geny/Developer/store_manager_v2/app/jobs/shopify).
- Do not add ad hoc Shopify HTTP or GraphQL calls in random models or controllers.
- Reuse the shared Shopify transport and GraphQL objects, or extend them if the API shape changes.
- Keep pull logic, parsing, persistence, and push logic separated.
- Use the existing Shopify specs and payload fixtures instead of inventing large inline blobs.
