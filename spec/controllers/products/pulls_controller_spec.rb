# frozen_string_literal: true

require "rails_helper"

RSpec.describe Products::PullsController, type: :controller do
  before { sign_in_as_admin }
  after { log_out }

  describe "POST #create" do
    it "converts string limit to integer before enqueuing job" do
      allow(Shopify::PullProductsJob).to receive(:perform_later).with(limit: 50)
      allow(Config).to receive(:update_shopify_products_sync_time)

      post :create, params: {limit: "50"}

      expect(Shopify::PullProductsJob).to have_received(:perform_later).with(limit: 50)
      expect(response).to redirect_to(products_path)
      expect(flash[:notice]).to include("Success! Visit")
    end

    it "enqueues job with nil limit when omitted" do
      allow(Shopify::PullProductsJob).to receive(:perform_later).with(limit: nil)
      allow(Config).to receive(:update_shopify_products_sync_time)

      post :create

      expect(Shopify::PullProductsJob).to have_received(:perform_later).with(limit: nil)
      expect(response).to redirect_to(products_path)
    end
  end
end
