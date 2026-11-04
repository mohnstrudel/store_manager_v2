# frozen_string_literal: true

module Shopify
  class PullProductsJob < Shopify::BasePullJob
    private

    def pull_class
      Product::Shopify::Pull
    end
  end
end
