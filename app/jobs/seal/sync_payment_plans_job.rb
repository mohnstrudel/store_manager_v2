# frozen_string_literal: true

module Seal
  class SyncPaymentPlansJob < ApplicationJob
    queue_as :default

    def perform
      client = Seal::Api::Client.new
      selling_plans_by_id = client.selling_plans_by_id
      synced_at = Time.current

      client.each_subscription_detail do |subscription|
        snapshot = SalePaymentPlan::Seal::Parser.parse(
          subscription,
          selling_plans_by_id:,
          origin_date: origin_date_for(subscription)
        )
        SalePaymentPlan.reconcile!(
          attributes: snapshot.fetch(:attributes).merge(synced_at:),
          parts: snapshot.fetch(:parts)
        )
      end
    end

    private

    # Seal never reports the linked Shopify order's own creation date, so
    # conversion depends on that order already existing locally. A
    # subscription synced before its order is imported defers its money
    # until a later sync finds the now-linked Sale.
    def origin_date_for(subscription)
      Sale::Shopify::OrderId.find_sale(subscription["order_id"])&.shop_created_at&.to_date
    end
  end
end
