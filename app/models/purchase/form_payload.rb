# frozen_string_literal: true

class Purchase::FormPayload
  def initialize(params:)
    @params = params
  end

  def attributes
    purchase_params.to_h.except("warehouse_id").merge(
      "payments_attributes" => payments_attributes
    )
  end

  def initial_warehouse_id
    purchase_params[:warehouse_id].presence
  end

  private

  attr_reader :params

  def purchase_params
    @purchase_params ||= params.expect(
      purchase: [:supplier_id,
        :product_id,
        :edition_id,
        :order_reference,
        :item_price,
        :amount,
        :purchase_id,
        :selected_items_ids,
        :warehouse_id,
        payments_attributes: [:id, :value, :purchase_id]]
    )
  end

  def payments_attributes
    raw_params = params.dig(:purchase, :payments_attributes)
    return {} if raw_params.blank?

    raw_params.respond_to?(:to_unsafe_h) ? raw_params.to_unsafe_h : raw_params
  end
end
