# frozen_string_literal: true

module Woo
  class PushSaleJob < ApplicationJob
    queue_as :default

    def perform(sale)
      sale.push_status_to_woo_now
    end
  end
end
