# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sales::PullsController, type: :controller do
  before { sign_in_as_admin }
  after { log_out }

  describe "POST #create" do
    let(:sale) { create(:sale) }

    it "triggers the Woo pull job when the sale has a woo id" do
      allow(Woo::PullSalesJob).to receive_message_chain(:set, :perform_later).with(id: sale.woo_store_id)
      allow(Shopify::PullSaleJob).to receive(:perform_later)

      post :create, params: {sale_id: sale.to_param}

      expect(Woo::PullSalesJob).to have_received(:set).with(wait: 90.seconds)
    end

    it "triggers the Shopify pull job when the sale has a shopify id" do
      allow(Woo::PullSalesJob).to receive(:perform_later)
      allow(Shopify::PullSaleJob).to receive(:perform_later).with(sale.shopify_id)

      post :create, params: {sale_id: sale.to_param}

      expect(Shopify::PullSaleJob).to have_received(:perform_later).with(sale.shopify_id)
    end

    it "does not update the bulk sync timestamp" do
      allow(Config).to receive(:update_shopify_sales_sync_time)
      allow(Woo::PullSalesJob).to receive(:perform_later)
      allow(Shopify::PullSaleJob).to receive(:perform_later)

      post :create, params: {sale_id: sale.to_param}

      expect(Config).not_to have_received(:update_shopify_sales_sync_time)
    end
  end
end
