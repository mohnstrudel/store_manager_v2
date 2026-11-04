# frozen_string_literal: true

class Variant::Woo::Importer
  class << self
    def import(parsed_variant)
      return if parsed_variant.blank?

      product = Product.find_by_woo_id(parsed_variant[:product_woo_id])
      return if product.blank?

      prepared_options = parsed_variant[:options].reduce({}) do |acc, parsed_option|
        option_relation_name = parsed_option[:name].pluralize
        value = product.send(option_relation_name).find_or_create_by(value: parsed_option[:value])
        acc.merge({parsed_option[:name] => value})
      end

      variant = Variant.find_by_woo_id(parsed_variant[:woo_id])

      if variant.blank?
        variant = product.variants.find_by(prepared_options)
        if variant.blank?
          variant = product.variants.build(prepared_options)
          product.fill_variant_sku(variant, "woo-#{product.id}-#{parsed_variant[:woo_id]}")
          variant.save!
        end
      end

      woo_info = variant.woo_info || variant.store_infos.woo.new
      updates = {}
      updates[:store_id] = parsed_variant[:woo_id] if parsed_variant[:woo_id].present? && woo_info.store_id != parsed_variant[:woo_id]
      updates[:slug] = parsed_variant[:store_link] if parsed_variant[:store_link].present? && woo_info.slug != parsed_variant[:store_link]
      updates[:pull_time] = Time.zone.now

      if updates.any?
        if woo_info.persisted?
          woo_info.update(updates)
        else
          woo_info.assign_attributes(updates)
          woo_info.save!
        end
      end

      variant
    end
  end
end
