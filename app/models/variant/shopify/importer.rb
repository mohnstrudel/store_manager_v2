# frozen_string_literal: true

class Variant::Shopify::Importer
  attr_reader :product, :parsed, :sibling_store_ids, :variant
  private :product, :parsed, :sibling_store_ids, :variant

  def self.import!(product, parsed_payload, sibling_store_ids: [])
    raise ArgumentError, "Product cannot be blank" if product.blank?
    raise ArgumentError, "Payload cannot be blank" if parsed_payload.blank?

    new(product, parsed_payload, sibling_store_ids).update_or_create!
  end

  def initialize(product, parsed_payload, sibling_store_ids)
    @product = product
    @parsed = parsed_payload
    @sibling_store_ids = sibling_store_ids
  end

  def update_or_create!
    product.with_lock do
      find_or_initialize_variant
      variant.assign_attributes(variant_attrs)
      holder = identity_holder
      holder ? record_conflict(holder) : import_variant
    end
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

  def variant_identity_attrs
    @variant_identity_attrs ||= {
      color_id: variant_attrs[:color]&.id,
      size_id: variant_attrs[:size]&.id,
      version_id: variant_attrs[:version]&.id
    }
  end

  def variant_attrs
    @variant_attrs ||= build_variant_attrs
  end

  def build_variant_attrs
    attributes = {}
    attributes[:sku] = parsed[:sku].presence || generated_fallback_sku
    assign_shopify_selling_price(attributes)
    assign_shopify_purchase_cost(attributes)
    attributes[:weight] = parsed[:weight] if parsed[:weight].present?

    return attributes if parsed[:is_single_variant]

    parsed[:options].each do |option|
      case option[:name]
      when *Variant.shopify_types[:color]
        attributes[:color] = Color.find_or_create_by(value: option[:value])
        product.colors |= [attributes[:color]]
      when *Variant.shopify_types[:size]
        attributes[:size] = Size.find_or_create_by(value: option[:value])
        product.sizes |= [attributes[:size]]
      when *Variant.shopify_types[:version]
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

  def assign_shopify_selling_price(attributes)
    amount = parsed[:selling_price]
    return if amount.blank?

    rate = parsed[:usd_conversion_rate]
    attributes[:selling_price] = convert_to_usd(amount, rate, :selling_price)
    return unless rate

    attributes[:selling_price_source_amount] = amount
    attributes[:selling_price_source_currency] = "EUR"
    attributes[:selling_price_exchange_rate] = rate
    attributes[:selling_price_exchange_rate_date] = parsed.fetch(:usd_conversion_date)
  end

  def convert_to_usd(amount, rate, attribute)
    value = rate ? (amount.to_d * rate).round(2) : amount.to_d
    clamp_to_column(value, attribute)
  end

  def clamp_to_column(value, attribute)
    limit = column_limit(attribute)
    clamped = value.clamp(-limit, limit)
    return clamped if clamped == value

    Rails.logger.warn(
      "Variant::Shopify::Importer: clamped #{attribute} from #{value} to #{clamped} " \
      "for product_id=#{product.id} variant_store_id=#{parsed[:store_id].presence || "blank"}"
    )
    clamped
  end

  def column_limit(attribute)
    type = Variant.type_for_attribute(attribute)
    BigDecimal(10)**(type.precision - type.scale) - BigDecimal(10)**-type.scale
  end

  def assign_shopify_purchase_cost(attributes)
    amount = parsed[:purchase_cost]
    return if amount.blank?

    attributes[:purchase_cost] = convert_to_usd(amount, parsed[:usd_conversion_rate], :purchase_cost)
  end

  def identity_holder
    return variant if linked_to_sibling?

    product.variants.where(variant.slice(:color_id, :size_id, :version_id)).where.not(id: variant.id).first
  end

  def linked_to_sibling?
    linked_store_id = variant.shopify_info&.store_id
    linked_store_id.present? && linked_store_id != parsed[:store_id] && sibling_store_ids.include?(linked_store_id)
  end

  def record_conflict(holder)
    VariantImportConflict.record!(
      store_id: parsed[:store_id],
      product:,
      sku: parsed[:sku],
      options: Array(parsed[:options]),
      conflicting_variant: holder
    )
    nil
  end

  def import_variant
    variant.save!
    if parsed[:store_id]
      variant.upsert_shopify_info!(
        store_id: parsed[:store_id],
        ext_created_at: parsed.dig(:store_info, :ext_created_at),
        ext_updated_at: parsed.dig(:store_info, :ext_updated_at),
        pull_time: Time.zone.now
      )
      VariantImportConflict.resolve!(parsed[:store_id])
    end
    variant
  end
end
