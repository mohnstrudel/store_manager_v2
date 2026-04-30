# frozen_string_literal: true

module Product::VariantGeneration
  extend ActiveSupport::Concern

  BASE_VARIANT_ATTRIBUTES = {size_id: nil, version_id: nil, color_id: nil}.freeze

  included do
    before_validation :build_base_variant
  end

  def build_new_variants
    build_base_variant
    return unless sizes.any? || versions.any? || colors.any?

    variants.build(missing_variant_attributes)
  end

  def build_base_variant(sku: nil)
    variant = base_variant || variants.build(BASE_VARIANT_ATTRIBUTES)
    fill_variant_sku(variant, sku)
    variant
  end

  def base_variant
    variant_from_memory = association(:variants).target.find { |ed| base_variant?(ed) }
    return variant_from_memory if variant_from_memory || association(:variants).loaded?

    variants.find_by(BASE_VARIANT_ATTRIBUTES)
  end

  def fill_variant_sku(variant, seed)
    return if variant.sku.present?

    variant.sku = seed.presence || default_base_sku
  end

  def default_base_sku
    return "product-#{id}-base" if id.present?

    "#{title.to_s.parameterize.presence || "product"}-base-#{SecureRandom.hex(4)}"
  end

  def base_variant?(variant)
    variant.size_id.nil? && variant.version_id.nil? && variant.color_id.nil?
  end

  def fetch_variants_with_title
    variants.includes(:version, :color, :size).select { |variant| variant.title.present? }
  end

  private

  def missing_variant_attributes
    attributes = []
    size_options.each do |size|
      version_options.each do |version|
        color_options.each do |color|
          variant_attributes = {
            size_id: size&.id,
            version_id: version&.id,
            color_id: color&.id,
            sku: combination_sku(size:, version:, color:)
          }.compact_blank

          next if variants.exists?(variant_attributes.except(:sku))

          attributes << variant_attributes
        end
      end
    end
    attributes
  end

  def combination_sku(size:, version:, color:)
    dimensions = [size&.id, version&.id, color&.id].compact
    return "#{title.to_s.parameterize.presence || "product"}-variant" if dimensions.blank?

    "#{title.to_s.parameterize.presence || "product"}-#{dimensions.join("-")}"
  end

  def skip_single_size?
    sizes.count == 1 && (versions.any? || colors.any?)
  end

  def size_options = skip_single_size? ? [nil] : sizes.presence || [nil]
  def version_options = versions.presence || [nil]
  def color_options = colors.presence || [nil]
end
