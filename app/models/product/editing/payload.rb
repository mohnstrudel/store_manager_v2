# frozen_string_literal: true

class Product::Editing::Payload
  def initialize(params:)
    @params = params
  end

  def product_attributes
    attributes = product_params.to_h.symbolize_keys
    attributes[:brand_ids] = Array(attributes[:brand_ids]).reject(&:blank?) if attributes.key?(:brand_ids)
    attributes
  end

  def store_infos_attributes
    return [] if params[:store_infos].blank?

    row_values(params[:store_infos]).map do |attrs|
      attrs = attrs.symbolize_keys

      {
        id: attrs[:id].presence,
        tag_list: attrs[:tag_list],
        store_name: attrs[:store_name],
        destroy: boolean_type.cast(attrs[:_destroy])
      }.compact
    end
  end

  def variants_attributes
    row_values(params[:variants]).map do |attrs|
      attrs = attrs.symbolize_keys

      {
        id: attrs[:id].presence,
        sku: attrs[:sku],
        size_id: attrs[:size_id],
        version_id: attrs[:version_id],
        color_id: attrs[:color_id],
        purchase_cost: attrs[:purchase_cost],
        selling_price: attrs[:selling_price],
        weight: attrs[:weight],
        destroy: boolean_type.cast(attrs[:_destroy])
      }.compact
    end
  end

  def purchase_attributes
    raw_purchase_attributes.compact_blank.to_h.symbolize_keys
  end

  private

  attr_reader :params

  def product_params
    params.expect(product: [
      :title,
      :description,
      :franchise_id,
      :shape,
      brand_ids: []
    ])
  end

  def purchase_params
    params.expect(purchase: [
      :supplier_id,
      :order_reference,
      :item_price,
      :amount,
      :warehouse_id,
      :payment_value
    ])
  end

  def raw_purchase_attributes
    return {} if params[:purchase].blank?

    purchase_params.to_h.symbolize_keys
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
