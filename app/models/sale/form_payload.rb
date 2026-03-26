# frozen_string_literal: true

class Sale::FormPayload
  def initialize(params:)
    @params = params
  end

  def sale_attributes
    sale_params.to_h
  end

  def sale_item_attributes
    return [] if params[:sale_items].blank?

    sale_items_params.to_h.values.map do |attrs|
      attrs = attrs.with_indifferent_access

      {
        id: attrs[:id].presence,
        product_id: attrs[:product_id].presence,
        edition_id: attrs[:edition_id].presence,
        qty: attrs[:qty].presence,
        price: attrs[:price].presence,
        woo_id: attrs[:woo_id].presence,
        destroy: boolean_type.cast(attrs[:_destroy])
      }.compact
    end
  end

  def rebuild_submitted_sale_items(sale:, invalid_record: nil)
    return sale.sale_items.to_a if params[:sale_items].blank?

    sale_items_params.to_h.values.map.with_index do |attrs, index|
      attrs = attrs.with_indifferent_access
      sale_item = build_sale_item(sale:, attrs:, invalid_record:, index:)
      sale_item.assign_attributes(
        product_id: attrs[:product_id],
        edition_id: attrs[:edition_id],
        qty: attrs[:qty],
        price: attrs[:price],
        woo_id: attrs[:woo_id]
      )
      sale_item._destroy = attrs[:_destroy]
      sale_item
    end
  end

  private

  attr_reader :params

  def sale_params
    params.expect(
      sale: [
        :status,
        :address_1,
        :address_2,
        :city,
        :company,
        :country,
        :discount_total,
        :note,
        :postcode,
        :shipping_total,
        :state,
        :total,
        :woo_id,
        :customer_id
      ]
    )
  end

  def sale_items_params
    params.expect(
      sale_items: [[
        :id,
        :product_id,
        :edition_id,
        :qty,
        :price,
        :woo_id,
        :_destroy
      ]]
    )
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
    @first_new_sale_item_index ||= sale_items_params.to_h.values.find_index { |attrs| attrs[:id].blank? }
  end

  def boolean_type
    @boolean_type ||= ActiveModel::Type::Boolean.new
  end
end
