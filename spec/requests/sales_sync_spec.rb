# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Sales Sync API" do
  before { sign_in_as_admin }

  describe "POST /sales/pull" do
    it "enqueues Shopify and delayed Woo sync without enqueuing Seal directly", :aggregate_failures do
      allow(Config).to receive(:update_shopify_sales_sync_time)
      allow(Shopify::PullSalesJob).to receive(:perform_later).with(limit: nil)
      allow(Woo::PullSalesJob).to receive_message_chain(:set, :perform_later).with(limit: nil)
      allow(Seal::SyncPaymentPlansJob).to receive(:perform_later)

      post sales_bulk_pull_path

      expect(Config).to have_received(:update_shopify_sales_sync_time)
      expect(Shopify::PullSalesJob).to have_received(:perform_later).with(limit: nil)
      expect(Woo::PullSalesJob).to have_received(:set).with(wait: 90.seconds)
      expect(Seal::SyncPaymentPlansJob).not_to have_received(:perform_later)
    end

    it "passes the limit parameter through to the Shopify and Woo jobs", :aggregate_failures do
      allow(Config).to receive(:update_shopify_sales_sync_time)
      allow(Shopify::PullSalesJob).to receive(:perform_later).with(limit: "100")
      allow(Woo::PullSalesJob).to receive_message_chain(:set, :perform_later).with(limit: "100")

      post sales_bulk_pull_path(limit: 100)

      expect(Shopify::PullSalesJob).to have_received(:perform_later).with(limit: "100")
      expect(Woo::PullSalesJob).to have_received(:set).with(wait: 90.seconds)
    end

    it "redirects back with a jobs dashboard notice", :aggregate_failures do
      allow(Config).to receive(:update_shopify_sales_sync_time)
      allow(Shopify::PullSalesJob).to receive(:perform_later)
      allow(Woo::PullSalesJob).to receive_message_chain(:set, :perform_later)

      post sales_bulk_pull_path

      expect(response).to redirect_to(sales_path)
      expect(flash[:notice]).to include(message: "Success! Visit")
      expect(flash[:notice]).to include(link: hash_including(label: "jobs statuses dashboard"))
    end
  end
end
