# frozen_string_literal: true

module Seal
  class ReconcileInstallmentSaleItemsJob < ApplicationJob
    queue_as :default

    def perform(sale_id: nil)
      SalePaymentPlan.seal.affecting_sale(sale_id).find_each(&:reconcile_installment_attribution!)
    end
  end
end
