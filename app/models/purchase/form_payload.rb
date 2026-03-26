# frozen_string_literal: true

class Purchase::FormPayload
  def initialize(params:)
    @params = params
  end

  def attributes
    purchase_params.to_h.except("warehouse_id")
  end

  def initial_warehouse_id
    purchase_params[:warehouse_id].presence
  end

  def initial_payment_value
    initial_payment_params[:value].presence
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
        :warehouse_id]
    )
  end

  def initial_payment_params
    return {}.with_indifferent_access if params[:initial_payment].blank?

    @initial_payment_params ||= params.expect(initial_payment: [:value]).to_h.with_indifferent_access
  end
end
