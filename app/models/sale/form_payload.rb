# frozen_string_literal: true

class Sale::FormPayload
  ADDRESS_FIELDS = %i[first_name last_name email phone company address_1 address_2 city state postcode country].freeze

  def initialize(params:)
    @params = params
  end

  def sale_attributes
    sale_params.to_h.symbolize_keys
  end

  def shipping_address_attributes
    address_params_for(:shipping_address)
  end

  def billing_address_attributes
    address_params_for(:billing_address)
  end

  def sale_item_attributes
    submitted_sale_item_attributes.map do |attrs|
      {
        id: attrs[:id].presence,
        product_id: attrs[:product_id].presence,
        variant_id: attrs[:variant_id].presence,
        qty: attrs[:qty].presence,
        price: attrs[:price].presence,
        destroy: boolean_type.cast(attrs[:_destroy])
      }.compact
    end
  end

  def rebuild_submitted_sale_items(sale:, invalid_record: nil)
    return sale.sale_items.to_a if submitted_sale_item_attributes.empty?

    submitted_sale_item_attributes.map.with_index do |attrs, index|
      sale_item = build_sale_item(sale:, attrs:, invalid_record:, index:)
      sale_item.assign_attributes(
        product_id: attrs[:product_id],
        variant_id: attrs[:variant_id],
        qty: attrs[:qty],
        price: attrs[:price]
      )
      sale_item._destroy = attrs[:_destroy]
      sale_item
    end
  end

  private

  attr_reader :params

  def address_params_for(kind)
    nested = params.dig(:sale, kind)
    return {} if nested.blank?

    nested.permit(*ADDRESS_FIELDS).to_h.symbolize_keys
  end

  def sale_params
    params.expect(
      sale: [
        :status,
        :discount_total,
        :note,
        :shipping_total,
        :total,
        :customer_id
      ]
    )
  end

  def submitted_sale_item_attributes
    row_values(params[:sale_items]).map { |attrs| attrs.symbolize_keys }
  end

  def build_sale_item(sale:, attrs:, invalid_record:, index:)
    return invalid_record if invalid_sale_item?(invalid_record, attrs, index)
    return sale.sale_items.find_by(id: attrs[:id]) if attrs[:id].present?

    SaleItem.new(sale:)
  end

  def invalid_sale_item?(invalid_record, attrs, index)
    return false unless invalid_record.is_a?(SaleItem)

    if attrs[:id].present?
      invalid_record.id.to_s == attrs[:id].to_s
    else
      invalid_record.new_record? && index == first_new_sale_item_index
    end
  end

  def first_new_sale_item_index
    @first_new_sale_item_index ||= submitted_sale_item_attributes.find_index { |attrs| attrs[:id].blank? }
  end

  def boolean_type
    @boolean_type ||= ActiveModel::Type::Boolean.new
  end

  def row_values(value)
    case value
    when ActionController::Parameters
      value.to_unsafe_h.values
    when Hash
      value.values
    when Array
      value.map { |v| v.is_a?(ActionController::Parameters) ? v.to_unsafe_h : v }
    else
      []
    end
  end
end
