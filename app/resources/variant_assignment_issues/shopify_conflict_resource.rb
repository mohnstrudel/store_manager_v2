# frozen_string_literal: true

class VariantAssignmentIssues::ShopifyConflictResource < VariantAssignmentIssues::IssueResource
  typelize_from VariantImportConflict

  typelize '"shopify_conflict"'
  attribute :kind do |_conflict|
    "shopify_conflict"
  end

  attributes :sku, :store_id

  typelize "Array<{ name: string; value: string }>"
  attribute :shopify_options do |conflict|
    conflict.options.map { |option| option.slice("name", "value").symbolize_keys }
  end

  attributes :product_id

  typelize :string, nullable: true
  attribute :product_title do |conflict|
    conflict.product.full_title
  end

  typelize :string
  attribute :edit_path do |conflict|
    edit_product_path(conflict.product)
  end

  typelize :string, nullable: true
  attribute :conflicting_variant_label do |conflict|
    assignment_label(conflict.conflicting_variant) if conflict.conflicting_variant
  end

  typelize :string, nullable: true
  attribute :conflicting_variant_sku do |conflict|
    conflict.conflicting_variant&.sku
  end
end
