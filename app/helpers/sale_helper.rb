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
end
