# frozen_string_literal: true

class VariantAssignmentIssues::IndexResource < ApplicationResource
  ISSUE_RESOURCES = {
    purchases: VariantAssignmentIssues::PurchaseResource,
    sale_items: VariantAssignmentIssues::SaleItemResource,
    purchase_item_links: VariantAssignmentIssues::PurchaseItemLinkResource,
    sku_collisions: VariantAssignmentIssues::SkuCollisionResource,
    shopify_conflicts: VariantAssignmentIssues::ShopifyConflictResource
  }.freeze

  REASON_LABELS = {
    "missing_product" => "Missing Product",
    "missing_variant" => "Missing Variant",
    "product_mismatch" => "Product / Variant mismatch",
    "purchase_identity" => "Purchase identity mismatch",
    "sale_item_identity" => "SaleItem identity mismatch"
  }.freeze

  ISSUE_TYPE = '"purchases" | "sale_items" | "purchase_item_links" | "sku_collisions" | "shopify_conflicts"'

  typelize ISSUE_TYPE
  attribute :issue_type do |page|
    page.fetch(:issue_type).to_s
  end

  typelize :string
  attribute :filter do |page|
    page.fetch(:reason).to_s
  end

  typelize({purchases: :number, sale_items: :number, purchase_item_links: :number, sku_collisions: :number, shopify_conflicts: :number})
  attribute :counts do |page|
    page.fetch(:integrity).counts
  end

  typelize :boolean
  attribute :repairable do |page|
    page.fetch(:integrity).repairable?
  end

  typelize "Array<{ value: string; label: string }>"
  attribute :filters do |page|
    page.fetch(:integrity).reasons_for(page.fetch(:issue_type)).map { |value| {value:, label: REASON_LABELS.fetch(value)} }
  end

  typelize "Array<VariantAssignmentIssuesPurchase | VariantAssignmentIssuesSaleItem | VariantAssignmentIssuesPurchaseItemLink | VariantAssignmentIssuesSkuCollision | VariantAssignmentIssuesShopifyConflict>"
  attribute :issues do |page|
    ISSUE_RESOURCES.fetch(page.fetch(:issue_type)).new(
      page.fetch(:records),
      params: {reasons: page.fetch(:reasons), siblings_by_sku: page.fetch(:siblings_by_sku)}
    ).serializable_hash
  end

  typelize "Pagination"
  attribute :pagination do |page|
    PaginationResource.for(page.fetch(:issues))
  end
end
