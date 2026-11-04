# frozen_string_literal: true

module ProductHelper
  def product_props(product)
    {
      id: product.id,
      full_title: product.full_title,
      path: product_path(product)
    }
  end

  def variant_availability_props(product, current_variant: nil)
    return nil unless product

    assignable_variants = product.assignable_variants.includes(:color, :size, :version).to_a
    mode = assignable_variants.any?(&:base_model?) ? "base" : "select"
    variants = assignable_variants

    if current_variant&.product_id == product.id && variants.none? { |variant| variant.id == current_variant.id }
      variants = [*variants, current_variant]
    end

    {
      mode:,
      variants: variants.map { |variant| variant_assignment_option_props(variant) }
    }
  end

  def variant_assignment_option_props(variant)
    {
      value: variant.id,
      label: variant.title.to_s,
      base_model: variant.base_model?
    }
  end
end
