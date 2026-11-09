# frozen_string_literal: true

module Shopify
  class PullSalesJob < Shopify::BasePullJob
    private

    def pull_class
      Sale::Shopify::Pull
    end

    def handle_terminal_page
      Seal::SyncPaymentPlansJob.perform_later
    end
  end
end
