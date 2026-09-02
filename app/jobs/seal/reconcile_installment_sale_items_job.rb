# frozen_string_literal: true

module Seal
  class ReconcileInstallmentSaleItemsJob < ApplicationJob
    queue_as :default

    def perform(sale_id: nil)
      plans_to_reconcile(sale_id).find_each(&:reconcile_installment_attribution!)
    end

    private

    def plans_to_reconcile(sale_id)
      return SalePaymentPlan.seal if sale_id.blank?

      scope = SalePaymentPlan.seal.left_joins(:parts)
      scope
        .where(origin_sale_id: sale_id)
        .or(scope.where(sale_payment_parts: {sale_id:, active: true}))
        .distinct
    end
  end
end
