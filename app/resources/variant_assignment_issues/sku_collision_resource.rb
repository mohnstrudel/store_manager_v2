# frozen_string_literal: true

class VariantAssignmentIssues::SkuCollisionResource < VariantAssignmentIssues::IssueResource
  typelize_from Variant

  typelize '"sku_collision"'
  attribute :kind do |_variant|
    "sku_collision"
  end

  attributes :sku, :product_id

  typelize :string, nullable: true
  attribute :product_title do |variant|
    variant.product.full_title
  end

  typelize :string
  attribute :variant_label do |variant|
    assignment_label(variant)
  end

  typelize :string
  attribute :edit_path do |variant|
    edit_product_path(variant.product)
  end

  typelize "Array<{ product_id: number; product_title: string | null; variant_id: number; variant_label: string; edit_path: string }>"
  attribute :colliding_with do |variant|
    params.fetch(:siblings_by_sku).fetch(variant.sku, []).reject { |sibling| sibling.id == variant.id }.map do |other|
      {
        product_id: other.product_id,
        product_title: other.product.full_title,
        variant_id: other.id,
        variant_label: assignment_label(other),
        edit_path: edit_product_path(other.product)
      }
    end
  end
end
