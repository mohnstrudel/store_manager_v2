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
          selling_plans_by_id:
        )
        SalePaymentPlan.reconcile!(
          attributes: snapshot.fetch(:attributes).merge(synced_at:),
          parts: snapshot.fetch(:parts)
        )
      end
    end
  end
end
