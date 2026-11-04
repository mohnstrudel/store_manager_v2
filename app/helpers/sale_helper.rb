# frozen_string_literal: true

module SaleHelper
  def sale_payment_context_props(sale)
    {
      partially_paid: sale.payment_plans.empty? && sale.partially_paid?,
      payment_plans: SalePaymentPlanResource.new(sale.payment_plans, params: {sale:}).serializable_hash
    }
  end

  def sale_settlement_props(sale)
    SaleSettlementResource.new(sale).serializable_hash.symbolize_keys
  end

  def sale_summary_for_warehouse(sale)
    address = sale.shipping_address

    [
      sale.customer.full_name,
      address&.address_1,
      address&.address_2,
      address&.postcode,
      address&.city,
      address&.country,
      address&.phone.presence || sale.customer.phone
    ].compact_blank.join(", ")
  end

  def sale_address_for_clipboard(sale)
    address = sale.shipping_address

    [
      sale.customer.full_name,
      address&.address_2,
      address&.address_1,
      [address&.postcode, address&.city].compact_blank.join(" ").presence,
      address&.country,
      address&.phone.presence || sale.customer.phone
    ].compact_blank.join("\n")
  end
end
