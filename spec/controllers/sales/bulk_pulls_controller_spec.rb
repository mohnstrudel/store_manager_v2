# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sales::BulkPullsController, type: :controller do
  before { sign_in_as_admin }
  after { log_out }

  describe "POST #create" do
    it "triggers bulk sync jobs" do
      allow(Config).to receive(:update_shopify_sales_sync_time)
      allow(Shopify::PullSalesJob).to receive(:perform_later).with(limit: nil)
      allow(Woo::PullSalesJob).to receive_message_chain(:set, :perform_later).with(limit: nil)

      post :create

      expect(Config).to have_received(:update_shopify_sales_sync_time)
      expect(Shopify::PullSalesJob).to have_received(:perform_later).with(limit: nil)
      expect(Woo::PullSalesJob).to have_received(:set).with(wait: 90.seconds)
    end

    it "passes the limit parameter through to jobs" do
      allow(Config).to receive(:update_shopify_sales_sync_time)
      allow(Shopify::PullSalesJob).to receive(:perform_later).with(limit: "100")
      allow(Woo::PullSalesJob).to receive_message_chain(:set, :perform_later).with(limit: "100")

      post :create, params: {limit: 100}

      expect(Shopify::PullSalesJob).to have_received(:perform_later).with(limit: "100")
      expect(Woo::PullSalesJob).to have_received(:set).with(wait: 90.seconds)
    end

    it "sets a flash notice with the jobs dashboard link" do
      allow(Config).to receive(:update_shopify_sales_sync_time)
      allow(Shopify::PullSalesJob).to receive(:perform_later)
      allow(Woo::PullSalesJob).to receive_message_chain(:set, :perform_later)

      post :create

      expect(flash[:notice]).to include("Success! Visit")
      expect(flash[:notice]).to include("jobs statuses dashboard")
    end
  end
end
