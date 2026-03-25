# frozen_string_literal: true

class Product::FormPayload
  def initialize(params:)
    @params = params
  end

  def product_attributes
    product_params.to_h
  end

  def store_infos_attributes
    return [] if params[:store_infos].blank?

    store_infos_params.to_h.values.map do |attrs|
      attrs = attrs.with_indifferent_access

      {
        id: attrs[:id].presence,
        tag_list: attrs[:tag_list],
        store_name: attrs[:store_name],
        destroy: boolean_type.cast(attrs[:_destroy])
      }.compact
    end
  end

  def editions_attributes
    submitted_editions.map do |attrs|
      attrs = attrs.with_indifferent_access

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
    return {} if purchase_params.blank?

    attrs = purchase_params.to_h.with_indifferent_access
    payment_attrs = attrs[:payments_attributes]&.to_h

    {
      warehouse_id: attrs[:warehouse_id].presence,
      payment_value: payment_attrs&.values&.first&.fetch("value", nil)&.presence
    }.compact
  end

  def submitted_editions
    return [] if params[:editions].blank?

    editions_params.to_h.values
  end

  def submitted_store_infos
    return [] if params[:store_infos].blank?

    store_infos_params.to_h.values
  end

  private

  attr_reader :params

  def product_params
    params.expect(product: [
      :title,
      :description,
      :franchise_id,
      :shape_id,
      :sku,
      :woo_id,
      :shopify_id,
      brand_ids: [],
      color_ids: [],
      size_ids: [],
      version_ids: [],
      purchases_attributes: [[
        :item_price,
        :amount,
        :supplier_id,
        :order_reference,
        :warehouse_id,
        payments_attributes: [:value]
      ]]
    ])
  end

  def store_infos_params
    params.expect(store_infos: [[
      :id,
      :tag_list,
      :store_name,
      :_destroy
    ]])
  end

  def editions_params
    params.expect(editions: [[
      :id,
      :sku,
      :size_id,
      :version_id,
      :color_id,
      :purchase_cost,
      :selling_price,
      :weight,
      :_destroy
    ]])
  end

  def purchase_params
    raw_params = params.dig(:product, :purchases_attributes, "0")
    return if raw_params.blank?

    raw_params.respond_to?(:to_unsafe_h) ? raw_params.to_unsafe_h : raw_params
  end

  def boolean_type
    @boolean_type ||= ActiveModel::Type::Boolean.new
  end
end
