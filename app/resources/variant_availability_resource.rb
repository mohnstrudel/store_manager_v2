# frozen_string_literal: true

class VariantAvailabilityResource < ApplicationResource
  typelize '"base" | "select"'
  attribute :mode do |product|
    assignable_variants(product).any?(&:base_model?) ? "base" : "select"
  end

  typelize "Array<VariantAssignmentOption>"
  attribute :variants do |product|
    VariantAssignmentOptionResource.new(offered_variants(product)).serializable_hash
  end

  def offered_variants(product)
    variants = assignable_variants(product)
    current_variant = params[:current_variant]

    if current_variant&.product_id == product.id && variants.none? { |variant| variant.id == current_variant.id }
      [*variants, current_variant]
    else
      variants
    end
  end

  def assignable_variants(product)
    @assignable_variants ||= {}
    @assignable_variants[product.id] ||= product.assignable_variants.includes(:color, :size, :version).to_a
  end
end
