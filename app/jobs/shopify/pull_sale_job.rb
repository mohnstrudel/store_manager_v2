# frozen_string_literal: true

module Shopify
  class PullSaleJob < ApplicationJob
    def perform(sale_store_id)
      raise ArgumentError, "Sale store_id is required" if sale_store_id.blank?

      client = Shopify::Api::Client.new
      response = client.fetch_order(sale_store_id)

      parsed = Sale::Shopify::Parser.parse(response)
      sale = Sale::Shopify::Importer.import!(parsed)

      Seal::ReconcileInstallmentSaleItemsJob.perform_later(sale_id: sale.id) if linked_to_payment_plan?(sale)
    end

    private

    def linked_to_payment_plan?(sale)
      SalePaymentPlan.exists?(origin_sale_id: sale.id) ||
        SalePaymentPart.exists?(sale_id: sale.id, active: true)
    end
  end
end
