---
name: shopify
description: Use for Shopify Admin API work in this repo. The important local rule is that GraphQL calls go through the shared client and query or mutation objects, with sync logic kept in jobs and parser or serializer layers.
---

# Shopify

- The GraphQL client lives in [app/services/shopify/api/client.rb](/Users/geny/Developer/store_manager_v2/app/services/shopify/api/client.rb).
- Query and mutation objects live under [app/services/shopify/graphql](/Users/geny/Developer/store_manager_v2/app/services/shopify/graphql).
- Sync orchestration lives in [app/jobs/shopify](/Users/geny/Developer/store_manager_v2/app/jobs/shopify).
- Do not add ad hoc Shopify HTTP or GraphQL calls in random models or controllers.
- Reuse the shared client and GraphQL objects, or extend them if the API shape changes.
- Keep pull logic, parsing, persistence, and push logic separated.
- Use the existing Shopify specs and payload fixtures instead of inventing large inline blobs.
