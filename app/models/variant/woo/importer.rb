# frozen_string_literal: true

class Variant::Woo::Importer
  attr_reader :parsed_variant, :product
  private :parsed_variant, :product

  def self.import(parsed_variant)
    return if parsed_variant.blank?

    product = Product.find_by_woo_id(parsed_variant[:product_woo_id])
    return if product.blank?

    new(parsed_variant, product).import
  end

  def initialize(parsed_variant, product)
    @parsed_variant = parsed_variant
    @product = product
  end

  def import
    variant = find_or_create_variant
    sync_woo_info(variant) if variant
    variant
  end

  private

  def find_or_create_variant
    return product.variants.where_woo_ids(parsed_variant[:woo_id]).first if parsed_variant[:options].blank?

    options = prepared_options

    Variant.find_by_woo_id(parsed_variant[:woo_id]) ||
      product.variants.find_by(options) ||
      build_variant
  end

  def prepared_options
    @prepared_options ||= parsed_variant[:options].reduce({}) do |acc, parsed_option|
      option_relation_name = parsed_option[:name].pluralize
      value = product.send(option_relation_name).find_or_create_by(value: parsed_option[:value])
      acc.merge({parsed_option[:name] => value})
    end
  end

  def build_variant
    variant = product.variants.build(prepared_options)
    product.fill_variant_sku(variant, "woo-#{product.id}-#{parsed_variant[:woo_id]}")
    variant.save!
    variant
  end

  def sync_woo_info(variant)
    woo_info = variant.woo_info || variant.store_infos.woo.new
    updates = woo_info_updates(woo_info)

    if woo_info.persisted?
      woo_info.update(updates)
    else
      woo_info.assign_attributes(updates)
      woo_info.save!
    end
  end

  def woo_info_updates(woo_info)
    updates = {}
    updates[:store_id] = parsed_variant[:woo_id] if parsed_variant[:woo_id].present? && woo_info.store_id != parsed_variant[:woo_id]
    updates[:slug] = parsed_variant[:store_link] if parsed_variant[:store_link].present? && woo_info.slug != parsed_variant[:store_link]
    updates[:pull_time] = Time.zone.now
    updates
  end
end
