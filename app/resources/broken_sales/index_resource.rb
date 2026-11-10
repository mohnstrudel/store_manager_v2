# frozen_string_literal: true

class BrokenSales::IndexResource < ApplicationResource
  ISSUE_RESOURCES = {
    purchases: BrokenSales::PurchaseResource,
    sale_items: BrokenSales::SaleItemResource,
    import_failures: BrokenSales::ImportFailureResource,
    purchase_item_links: BrokenSales::PurchaseItemLinkResource,
    sku_collisions: BrokenSales::SkuCollisionResource,
    shopify_conflicts: BrokenSales::ShopifyConflictResource
  }.freeze

  VIEW_RESOURCES = {
    "products" => BrokenSales::ProductRowResource
  }.freeze

  REASON_LABELS = {
    "missing_product" => "Missing Product",
    "missing_variant" => "Missing Variant",
    "product_mismatch" => "Product / Variant mismatch",
    "purchase_identity" => "Purchase identity mismatch",
    "sale_item_identity" => "SaleItem identity mismatch"
  }.freeze

  ISSUE_TYPE = '"purchases" | "sale_items" | "import_failures" | "purchase_item_links" | "sku_collisions" | "shopify_conflicts"'

  typelize ISSUE_TYPE
  attribute :issue_type do |page|
    page.fetch(:issue_type).to_s
  end

  typelize '"orders" | "products"', nullable: true
  attribute :view do |page|
    page.fetch(:view)
  end

  typelize :string
  attribute :filter do |page|
    page.fetch(:reason).to_s
  end

  typelize '"active" | "all" | "closed"', nullable: true
  attribute :scope do |page|
    page.fetch(:scope)
  end

  typelize :number, nullable: true
  attribute :product_id do |page|
    page.fetch(:product)&.id
  end

  typelize :string, nullable: true
  attribute :product_title do |page|
    page.fetch(:product)&.full_title
  end

  typelize({purchases: :number, sale_items: :number, import_failures: :number, purchase_item_links: :number, sku_collisions: :number, shopify_conflicts: :number})
  attribute :counts do |page|
    page.fetch(:counts)
  end

  typelize :boolean
  attribute :repairable do |page|
    page.fetch(:integrity).repairable?
  end

  typelize "Array<{ value: string; label: string }>"
  attribute :filters do |page|
    page.fetch(:filters).map { |value| {value:, label: REASON_LABELS.fetch(value)} }
  end

  typelize "Array<BrokenSalesPurchase | BrokenSalesSaleItem | BrokenSalesPurchaseItemLink | BrokenSalesSkuCollision | BrokenSalesShopifyConflict | BrokenSalesProductRow | BrokenSalesImportFailure>"
  attribute :issues do |page|
    resource = VIEW_RESOURCES.fetch(page.fetch(:view)) { ISSUE_RESOURCES.fetch(page.fetch(:issue_type)) }
    resource.new(
      page.fetch(:records),
      params: page.slice(:reasons, :siblings_by_sku, :import_failures_by_sale_id, :replacements_by_identity, :impact)
    ).serializable_hash
  end

  typelize "Pagination"
  attribute :pagination do |page|
    PaginationResource.for(page.fetch(:issues))
  end
end
