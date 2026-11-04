# frozen_string_literal: true

class Variant::Woo::Parser
  include Sanitizable

  class << self
    def parse_order_line_item(variant_api_response)
      possible_option_names = ["farbe", "color", "maßstab", "scale", "size", "version", "edition", "variant", "variante", "variants"]
      attributes = variant_api_response[:meta_data]
        .select { |el| el[:display_key].downcase.in? possible_option_names }

      return if attributes.blank?

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

  private_class_method :prepare_options
end
