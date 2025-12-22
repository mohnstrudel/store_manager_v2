# frozen_string_literal: true
class Woo::Edition
  include Sanitizable

  class << self
    def deserialize(edition_api_response)
      return if edition_api_response.blank?
      return if edition_api_response[:attributes].blank?

      {
        woo_id: edition_api_response[:id],
        product_woo_id: edition_api_response[:parent_id],
        store_link: edition_api_response[:permalink],
        options: prepare_options(edition_api_response[:attributes])
      }
    end

    def deserialize_from_order_response(edition_api_response)
      possible_option_names = ["farbe", "color", "maßstab", "scale", "size", "version", "edition", "variante", "variants"]
      attributes = edition_api_response[:meta_data]
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

      woo_id = edition_api_response[:variation_id] if edition_api_response[:variation_id].to_i.positive?

      {
        woo_id:,
        product_woo_id: edition_api_response[:product_id],
        options: prepare_options(attributes)
      }
    end

    def import(parsed_edition)
      return if parsed_edition.blank?

      product = Product.find_by(woo_id: parsed_edition[:product_woo_id])
      return if product.blank?

      # We need to find or create parsed options on the parent product first
      prepared_options = parsed_edition[:options].reduce({}) do |acc, parsed_option|
        option_relation_name = parsed_option[:name].pluralize
        value = product.send(option_relation_name).find_or_create_by(value: parsed_option[:value])
        acc.merge({parsed_option[:name] => value})
      end

      edition = Edition.find_by(woo_id: parsed_edition[:woo_id])

      if edition.blank?
        edition = product.editions.find_or_create_by(prepared_options)
      end

      if parsed_edition[:woo_id].present? && edition.woo_id != parsed_edition[:woo_id]
        edition.update(woo_id: parsed_edition[:woo_id])
      end

      edition
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
        when "version", "edition", "variante", "variants"
          {
            name: "version",
            value: smart_titleize(sanitize(attr[:option]))
          }
        end
      end.compact
    end
  end
end
