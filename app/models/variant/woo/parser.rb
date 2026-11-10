# frozen_string_literal: true

class Variant::Woo::Parser
  include Sanitizable

  POSSIBLE_OPTION_NAMES = ["farbe", "color", "maßstab", "scale", "size", "version", "edition", "variant", "variante", "variants"].freeze

  attr_reader :line_item
  private :line_item

  def self.parse_order_line_item(line_item)
    new(line_item).parse
  end

  def initialize(line_item)
    @line_item = line_item
  end

  def parse
    woo_id = line_item[:variation_id] if line_item[:variation_id].to_i.positive?

    return if option_attributes.blank? && woo_id.blank?

    {
      woo_id:,
      product_woo_id: line_item[:product_id],
      options: prepare_options
    }
  end

  private

  def option_attributes
    @option_attributes ||= line_item[:meta_data]
      .select { |el| el[:display_key].downcase.in? POSSIBLE_OPTION_NAMES }
      .map do |parsed_option|
        parsed_option.slice(:display_key, :display_value)
          .transform_keys({
            display_key: :name,
            display_value: :option
          })
      end
  end

  def prepare_options
    option_attributes.map do |attr|
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
