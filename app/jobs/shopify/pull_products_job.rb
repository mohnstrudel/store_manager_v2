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

    def stamp_past_failures?
      false
    end

    def stamp_sync(started_at)
      Config.update_shopify_products_sync_time(started_at)
    end

    def job_title
      "Shopify products pull"
    end

    def failure_notification(error)
      message = if error.is_a?(Shopify::Pull::Failed)
        "Some Shopify products could not be pulled."
      else
        "The Shopify products pull stopped before it finished."
      end

      {message:, link: jobs_dashboard_link}
    end
  end
end
