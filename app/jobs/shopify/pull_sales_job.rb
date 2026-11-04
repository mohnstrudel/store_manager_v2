# frozen_string_literal: true

module Shopify
  class PullSalesJob < Shopify::BasePullJob
    private

    def handle_page(page)
      page.failures.each do |failure|
        Rails.logger.error("Skipping Shopify order due to import failure: #{failure.message}")
      end
    end

    def pull_class
      Sale::Shopify::Pull
    end

    def handle_terminal_page
      Seal::SyncPaymentPlansJob.perform_later
    end
  end
end
