# frozen_string_literal: true

require "zlib"

module Seal
  class SyncPaymentPlansJob < ApplicationJob
    queue_as :default

    LOCK_KEY = Zlib.crc32(name)

    def perform
      return unless acquire_lock!

      begin
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

        Seal::ReconcileInstallmentSaleItemsJob.perform_later
      ensure
        release_lock!
      end
    end

    private

    def acquire_lock!
      ActiveModel::Type::Boolean.new.cast(
        ActiveRecord::Base.connection.select_value("SELECT pg_try_advisory_lock(#{LOCK_KEY})")
      )
    end

    def origin_date_for(subscription)
      Sale::Shopify::OrderId.find_sale(subscription["order_id"])&.shop_created_at&.to_date
    end

    def release_lock!
      ActiveRecord::Base.connection.execute("SELECT pg_advisory_unlock(#{LOCK_KEY})")
    end
  end
end
