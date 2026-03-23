# frozen_string_literal: true

class Edition::Shopify::Importer
  class Error < StandardError; end

  attr_reader :product, :parsed, :edition
  private :product, :parsed, :edition

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
    return nil if parsed[:options].blank?

    find_or_initialize_edition
    update_or_create_edition!
    update_shopify_store_info! if parsed[:store_id]

    edition
  rescue ActiveRecord::RecordInvalid => e
    handle_record_invalid(e)
  end

  private

  def update_or_create_edition!
    ActiveRecord::Base.transaction do
      edition.assign_attributes(edition_attrs)
      edition.save!
    end
  end

  def find_or_initialize_edition
    @edition = Edition.find_by_shopify_id(parsed[:store_id]) if parsed[:store_id]

    if edition.nil? || belongs_to_different_product?
      @edition = lookup_attrs.present? ? product.editions.where(lookup_attrs).first_or_initialize : product.editions.new
    end
  end

  def belongs_to_different_product?
    edition&.product_id != product.id
  end

  def edition_attrs
    @edition_attrs ||= build_edition_attrs
  end

  def lookup_attrs
    @lookup_attrs ||= edition_attrs.except(:sku, :selling_price, :purchase_cost, :weight)
  end

  def build_edition_attrs
    attributes = {}
    attributes[:sku] = parsed[:sku] if parsed[:sku].present?
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
      when "Version", "Edition", "Variante", "Variants"
        attributes[:version] = Version.find_or_create_by(value: option[:value])
        product.versions |= [attributes[:version]]
      end
    end

    attributes
  end

  def update_shopify_store_info!
    store_info = edition.shopify_info || edition.store_infos.shopify.new
    store_info.assign_attributes(
      store_id: parsed[:store_id],
      pull_time: Time.zone.now,
      ext_created_at: parsed.dig(:store_info, :ext_created_at),
      ext_updated_at: parsed.dig(:store_info, :ext_updated_at)
    )
    store_info.save!
  end

  def handle_record_invalid(error)
    model_name = error.record.class.name
    detailed_errors = error.record.errors.full_messages.join(", ")
    store_id_details = "store_id: #{parsed[:store_id]}"
    raise Error, "Failed to process #{model_name}: #{detailed_errors}\n#{store_id_details}"
  end
end
