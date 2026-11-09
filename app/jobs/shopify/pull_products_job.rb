# frozen_string_literal: true

module Shopify
  class PullProductsJob < Shopify::BasePullJob
    private

    def last_sync_at
      Config.shopify_products_sync_at
    end

    def pull_class
      Product::Shopify::Pull
    end

    def stamp_sync(started_at)
      Config.update_shopify_products_sync_time(started_at)
    end
  end
end
