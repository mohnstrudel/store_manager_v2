# frozen_string_literal: true

class Woo::Variant
  include Sanitizable

  class << self
    def deserialize(variant_api_response)
      return if variant_api_response.blank?
      return if variant_api_response[:attributes].blank?

      {
        woo_id: variant_api_response[:id],
        product_woo_id: variant_api_response[:parent_id],
        store_link: variant_api_response[:permalink],
        options: prepare_options(variant_api_response[:attributes])
      }
    end

    def deserialize_from_order_response(variant_api_response)
      possible_option_names = ["farbe", "color", "maßstab", "scale", "size", "version", "edition", "variant", "variante", "variants"]
      attributes = variant_api_response[:meta_data]
        .select { |el| el[:display_key].downcase.in? possible_option_names }

      return if attributes.blank?

      # Rename keys for compatibility
      attributes = attributes.map do |parsed_option|
        parsed_option.slice(:display_key, :display_value)
          .transform_keys({
            display_key: :name,
            display_value: :option
          })
      end

      woo_id = variant_api_response[:variation_id] if variant_api_response[:variation_id].to_i.positive?

      {
        woo_id:,
        product_woo_id: variant_api_response[:product_id],
        options: prepare_options(attributes)
      }
    end

    def import(parsed_variant)
      return if parsed_variant.blank?

      product = Product.find_by_woo_id(parsed_variant[:product_woo_id])
      return if product.blank?

      # We need to find or create parsed options on the parent product first
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

    private

    def prepare_options(attributes)
      attributes.map do |attr|
        next if attr[:option].blank?

        case attr[:name].downcase
        when "farbe", "color"
          {
            name: "color",
            value: smart_titleize(attr[:option])
          }
        when "maßstab", "scale", "size"
          {
            name: "size",
            value: Size.sanitize_size(attr[:option])
          }
        when "version", "edition", "variant", "variante", "variants"
          {
            name: "version",
            value: smart_titleize(sanitize(attr[:option]))
          }
        end
      end.compact
    end
  end
end
