# Catalog and Order Refactors

Use this guide when refactoring a legacy Rails app with `Product`, `Sale` or `Order`, `Purchase`, `Inventory`, `Warehouse`, or store-integration models that currently mix model logic, controller transactions, and service objects.

## Core Read

- Legacy commerce apps often have the right domain logic, but the ownership is blurry.
- The goal is usually not to invent more layers.
- The goal is to move each behavior closer to the aggregate that already owns it.
- Do not treat the current legacy placement as the target architecture.
- Treat the current placement as input data for the refactor.

## Default Rule For Legacy Apps

- If logic belongs to one aggregate, first ask which file under `app/models/<model>/` it should live in.
- Do not default to keeping logic in:
- the base model file
- a controller transaction
- a generic `app/services` class
- a tiny query wrapper

- Legacy code is not precedent by itself.
- Preserve only the parts that already express a coherent boundary.

## 1. What To Preserve

- Preserve model-namespaced integration objects when they are already anchored to one concept.
- Good examples:
- `Product::ShopifyImporter`
- `Product::ShopifyParser`
- `Product::ShopifySerializer`
- `Sale::ShopifyImporter`
- `Sale::ShopifyParser`

- These are usually better as model-adjacent domain collaborators than as generic `app/services` dumping-ground classes.
- Preserve true cross-cutting concerns such as reusable `Searchable` or `Shopable` modules when they really apply across multiple models.

## 1A. How To Refactor Model-Owned Integration Slices

- A Fizzy-like refactor does not usually move model-specific integration mapping out of `app/models`.
- It usually makes the ownership and naming clearer.
- If several files all describe how one aggregate talks to one external system, group them under the aggregate namespace first.

Good target shapes:
- `app/models/product/shopify/parser.rb`
- `app/models/product/shopify/importer.rb`
- `app/models/product/shopify/payload.rb`
- `app/models/product/shopify/exporter.rb`
- `app/models/sale/shopify/parser.rb`
- `app/models/sale/shopify/importer.rb`

- Prefer a nested namespace such as `Product::Shopify::Parser` over a flat suffix file such as `Product::ShopifyParser` when:
- there are several related files for the same integration
- the integration has both inbound and outbound directions
- the aggregate has multiple Shopify-specific collaborators

- Keep low-level transport and API wiring outside the aggregate namespace.
- Good homes for those are:
- API clients
- GraphQL query builders
- webhook signature verification
- generic retry or rate-limit wrappers

- Keep aggregate-specific mapping and upsert logic near the aggregate.
- Good homes for those are:
- payload normalization
- remote-to-local attribute translation
- import and upsert rules
- outbound payload building
- aggregate-specific sync entry points

- `Parser` is a good name when the object converts external payloads into normalized domain attributes.
- `Importer` is a good name when the object takes normalized or raw remote data and creates or updates local records.
- `Serializer` is often a weaker name.
- If the object builds outbound API data, prefer `Payload` or `Exporter` when that is clearer.

- Keep readability of the original files in mind.
- The refactor goal is not to turn a straightforward importer into an abstract framework.
- Preserve obvious steps such as:
- parse remote payload
- normalize attributes
- upsert aggregate
- sync child records
- enqueue follow-up work

- If a tiny query object exists only to preload a relation for one sync path, fold it back into a named scope on the owning model.
- Example:
- `Shopify::ProductsQuery.for_media_sync(Product.all)` often becomes `Product.for_media_sync`

## 2. Product Refactor Map

- A large `Product` model often hides several cohesive capabilities.
- Typical capability split:
- `Product::Titling`
- `Product::Editions`
- `Product::SalesHistory`
- `Product::StoreReferences`
- `Product::Listing`

- `Product::Titling` is a strong home for:
- `generate_full_title`
- `update_full_title`
- `find_slug_candidate`
- title-building helpers

- `Product::Editions` is a strong home for:
- `build_new_editions`
- `fetch_editions_with_title`
- base-model and option-combination rules
- SKU and edition-combination validation helpers

When edition generation is a real option matrix, keep the core loop readable.
- Prefer extracting rule names such as `base_model?`, `skip_single_size?`, `size_options`, `version_options`, and `color_options`.
- Do not replace an understandable nested loop with a generic combinator framework just to make the code look more abstract.
- The first refactor should usually be moving the logic into `app/models/product/editions.rb`, not changing the algorithm style.

- `Product::SalesHistory` is a strong home for:
- active and completed sale-item history
- edition sale totals
- edition purchase totals

- `Product::StoreReferences` is a strong home for:
- storefront URLs
- shop-reference display helpers
- product-level store-info coordination that belongs to the aggregate

- `Product::Listing` is a strong home for repeated preload shapes such as:
- index preload
- detail preload
- sync preload

- Keep the base `Product` file as the composition root: associations, validations, a few broad scopes, and included capability modules.

Default file targets:
- `app/models/product/titling.rb`
- `app/models/product/editions.rb`
- `app/models/product/sales_history.rb`
- `app/models/product/store_references.rb`
- `app/models/product/listing.rb`
- optional workflow objects such as `app/models/product/upsert.rb`

## 3. Sale Refactor Map

- A `Sale` or `Order` model usually wants a split by business meaning, not by framework feature.
- Typical capability split:
- `Sale::Statuses`
- `Sale::Linking`
- `Sale::ShopSync`
- `Sale::Summaries`

- `Sale::Statuses` is a strong home for:
- active, completed, cancelled, and inactive status sets
- status scopes
- `active?`
- `completed?`
- remote-to-local status derivation such as `derive_status_from_shopify`

- `Sale::Linking` is a strong home for:
- `link_with_purchase_items`
- `has_unlinked_sale_items?`
- linkability checks and matching rules

- `Sale::ShopSync` is a strong home for:
- recent remote lookup
- remote timestamp helpers
- remote push or pull enqueue entry points

- `Sale::Summaries` is a strong home for:
- warehouse summaries
- select titles
- domain-level text representations used in more than one place

- If a title helper is only screen chrome, move it to helpers.
- If it is reused by mailers, notifications, selects, exports, or integrations, keeping it near the model is reasonable.

Default file targets:
- `app/models/sale/statuses.rb`
- `app/models/sale/linking.rb`
- `app/models/sale/shop_sync.rb`
- `app/models/sale/summaries.rb`
- optional workflow objects such as `app/models/sale/creation.rb`

## 4. Connected Models Usually Reveal Better Boundaries

- `SaleItem` and `PurchaseItem` often expose the real workflow seams.
- Watch for these patterns:
- relation-local matching
- warehouse relocation
- notification fan-out
- shipping-total maintenance
- derived counters and progress

- Common refactor targets:
- `Purchase::Financials`
- `Purchase::Warehousing`
- `Purchase::SaleLinking`
- `PurchaseItem::Shipping`
- `PurchaseItem::Relocatable`
- `Warehouse::Relocation`

- This keeps related commands, scopes, and callbacks close to the state they mutate.

Default file targets:
- `app/models/purchase/financials.rb`
- `app/models/purchase/warehousing.rb`
- `app/models/purchase/sale_linking.rb`
- `app/models/purchase_item/shipping.rb`
- `app/models/purchase_item/relocatable.rb`
- `app/models/warehouse/relocation.rb`

## 5. When A Service Should Become A Model-Area Workflow Object

- A service is often really a domain workflow object when it:
- operates on one aggregate plus its children
- uses mostly local records rather than external IO
- encodes matching, relocation, or notification rules for one business concept
- would read more clearly under `app/models/<namespace>/`

- Strong examples:
- `PurchaseLinker` often belongs as `Sale::Linker` or `Purchase::Linker`
- `ProductMover` often belongs as `PurchaseItem::Mover` or `Warehouse::Relocation`
- `PurchasedNotifier` often belongs as `PurchaseItem::Notifier`, `Purchase::Notifier`, or `WarehouseTransition::Notifier`

- The point is not the exact class name.
- The point is to move the workflow next to the domain that gives it meaning.

## 6. When A Query Object Is Too Small To Exist

- Query objects are justified when they have:
- persistence
- params normalization
- summaries
- multiple backends
- a user-facing identity

- A tiny wrapper that only adds one `includes`, `order`, or preload shape is usually better as a named scope.
- Example shape:
- `Shopify::ProductsQuery.for_media_sync(scope = Product.all)`

- In many apps this is clearer as:
- `Product.for_media_sync`
- or `scope :for_media_sync, -> { includes(...) }`

## 7. Controller Refactors For This Kind of App

- Heavy `create` and `update` actions in catalog or sales controllers often mean the controller is coordinating one aggregate's workflow.
- Do not jump straight to `app/services`.
- First try a model-area workflow object such as:
- `Product::CatalogChange`
- `Product::Upsert`
- `Sale::Creation`
- `Sale::StatusChange`

- Good candidates are controller transactions that touch:
- the main record
- nested child rows
- store-info updates
- media changes
- aggregate-owned matching or linking

- Keep the controller responsible for request loading, params, and response format.

## 8. What This Kind of App Already Gets Right

- A legacy app can already contain the seeds of the desired architecture.
- Good signs include:
- model-namespaced importers and parsers
- concern-based cross-cutting behavior
- named preload scopes
- tests that already describe capability-level behavior

- Refactor by clarifying those boundaries, not by replacing them wholesale.

## 9. Suggested Migration Sequence

1. Start with one aggregate at a time, usually `Product` or `Sale`.
2. Keep the base model file but extract one cohesive capability module with no behavior change.
3. Move related scopes, predicates, and commands together.
4. Replace one controller-side transaction block with a model-area workflow object.
5. Move one service at a time into a model namespace if it is really domain-local.
6. Fold trivial query wrappers back into named scopes.
7. Realign specs so the new capability modules become the obvious test seam.

## 10. What Codex Should Notice In Similar Apps

- A fat model is not always the real problem; mixed ownership usually is.
- Service objects that only coordinate one aggregate often belong back under that aggregate.
- External integration clients and low-level API wrappers can stay separate.
- Model-namespaced importers, parsers, and serializers are usually worth preserving.
- The cleanest refactor is often to split by business capability before introducing any new abstraction tier.

## 11. What Codex Should Not Assume

- Do not assume that an existing `ProductsController#create` transaction is the right long-term home for product-upsert logic.
- Do not assume that an existing `PurchaseLinker` or `ProductMover` in `app/services` is therefore a good service boundary.
- Do not assume a tiny query object should survive if a named scope would say the same thing more clearly.
- Do not assume the current base model file should keep every method just because that is how the legacy app evolved.
