# frozen_string_literal: true

class Variant::Shopify::Importer
  attr_reader :product, :parsed, :variant
  private :product, :parsed, :variant

  def self.import!(product, parsed_payload)
    raise ArgumentError, "Product cannot be blank" if product.blank?
    raise ArgumentError, "Payload cannot be blank" if parsed_payload.blank?

    new(product, parsed_payload).update_or_create!
  end

  def initialize(product, parsed_payload)
    @product = product
    @parsed = parsed_payload
  end

  def update_or_create!
    product.with_lock do
      find_or_initialize_variant
      variant.assign_attributes(variant_attrs)
      variant.save!
      if parsed[:store_id]
        variant.upsert_shopify_info!(
          store_id: parsed[:store_id],
          ext_created_at: parsed.dig(:store_info, :ext_created_at),
          ext_updated_at: parsed.dig(:store_info, :ext_updated_at),
          pull_time: Time.zone.now
        )
      end
    end

    variant
  end

  private

  def find_or_initialize_variant
    @variant = Variant.find_by_shopify_id(parsed[:store_id]) if parsed[:store_id]

    if variant.nil? || belongs_to_different_product?
      @variant = product.variants.find_by(variant_identity_attrs) || product.variants.new
    end
  end

  def belongs_to_different_product?
    variant&.product_id != product.id
  end

  def variant_attrs
    @variant_attrs ||= build_variant_attrs
  end

  def variant_identity_attrs
    @variant_identity_attrs ||= variant_attrs
      .except(:sku, :selling_price, :purchase_cost, :weight)
      .presence || {
        color_id: nil,
        size_id: nil,
        version_id: nil
      }
  end

  def build_variant_attrs
    attributes = {}
    attributes[:sku] = parsed[:sku].presence || generated_fallback_sku
    attributes[:selling_price] = parsed[:selling_price] if parsed[:selling_price].present?
    attributes[:purchase_cost] = parsed[:purchase_cost] if parsed[:purchase_cost].present?
    attributes[:weight] = parsed[:weight] if parsed[:weight].present?

    return attributes if parsed[:is_single_variant]

    parsed[:options].each do |option|
      case option[:name]
      when "Color"
        attributes[:color] = Color.find_or_create_by(value: option[:value])
        product.colors |= [attributes[:color]]
      when "Size", "Scale"
        attributes[:size] = Size.find_or_create_by(value: option[:value])
        product.sizes |= [attributes[:size]]
      when "Version", "Edition", "Variant", "Variante", "Variants"
        attributes[:version] = Version.find_or_create_by(value: option[:value])
        product.versions |= [attributes[:version]]
      end
    end

    attributes
  end

  def generated_fallback_sku
    store_id_segment = parsed[:store_id].to_s.split("/").last.presence || SecureRandom.hex(4)
    "shopify-#{product.id}-#{store_id_segment}"
  end
end
