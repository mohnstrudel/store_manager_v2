# frozen_string_literal: true

module Shopify
  class PullProductJob < Shopify::ApiJob
    include NotifiesRequester

    queue_as :default
    sidekiq_options retry: false

    def perform(shopify_product_id, requested_by: nil)
      payload = Shopify::Api::Client.new.fetch_product(shopify_product_id)

      if payload.blank?
        Product.forget_shopify_listing(shopify_product_id)
      else
        Product::Shopify::Importer.import(Product::Shopify::Parser.parse(payload), force: true)
      end

      notify_requester_of_success("#{job_title} finished.")
    end

    private

    def job_title
      "Shopify product pull"
    end

    def failure_notification(_error)
      {message: "This product could not be pulled from Shopify.", link: jobs_dashboard_link}
    end
  end
end
