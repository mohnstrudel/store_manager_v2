# frozen_string_literal: true

module Shopify
  class PullSaleJob < ApplicationJob
    def perform(sale_store_id)
      raise ArgumentError, "Sale store_id is required" if sale_store_id.blank?

      response = Shopify::Api::Client.new.fetch_order(sale_store_id)
      sale = Sale::Shopify::Importer.import!(Sale::Shopify::Parser.parse(response))

      sale.reconcile_installment_sale_items_later if sale.linked_to_payment_plan?
    end
  end
end
