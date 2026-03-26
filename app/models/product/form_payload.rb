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

  def initial_purchase_attributes
    attrs = submitted_initial_purchase_attributes
    return {} if attrs.blank?
    return {} if attrs.values.all?(&:blank?)

    {
      supplier_id: attrs[:supplier_id].presence,
      order_reference: attrs[:order_reference].presence,
      item_price: attrs[:item_price].presence,
      amount: attrs[:amount].presence,
      warehouse_id: attrs[:warehouse_id].presence,
      payment_value: attrs[:payment_value].presence
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

  def submitted_initial_purchase_attributes
    return {} if params[:initial_purchase].blank?

    initial_purchase_params.to_h.with_indifferent_access
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
      version_ids: []
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

  def boolean_type
    @boolean_type ||= ActiveModel::Type::Boolean.new
  end

  def initial_purchase_params
    params.expect(initial_purchase: [
      :supplier_id,
      :order_reference,
      :item_price,
      :amount,
      :warehouse_id,
      :payment_value
    ])
  end
end
