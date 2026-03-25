# frozen_string_literal: true

require "rails_helper"

RSpec.describe Products::ShopifyPullsController, type: :controller do
  before { sign_in_as_admin }
  after { log_out }

  describe "POST #create" do
    context "when product is published to Shopify" do
      let(:product) { create(:product) }

      before do
        allow(Shopify::PullProductJob).to receive(:perform_later).with(product.shopify_info.store_id)
      end

      it "enqueues the Shopify pull product job" do
        post :create, params: {product_id: product.to_param}

        expect(Shopify::PullProductJob).to have_received(:perform_later).with(product.shopify_info.store_id)
      end

      it "redirects to products path with notice" do
        post :create, params: {product_id: product.to_param}

        expect(response).to redirect_to(products_path)
        expect(flash[:notice]).to eq("Product is being pulled from Shopify")
      end
    end

    context "when product is not published to Shopify" do
      let(:product) do
        record = build(:product)
        record.save(validate: false)
        record
      end

      before do
        allow(Shopify::PullProductJob).to receive(:perform_later)
      end

      it "does not enqueue a job" do
        post :create, params: {product_id: product.to_param}

        expect(Shopify::PullProductJob).not_to have_received(:perform_later)
      end

      it "redirects with an unpublished notice" do
        post :create, params: {product_id: product.to_param}

        expect(response).to redirect_to(products_path)
        expect(flash[:notice]).to eq("Product has not been published to Shopify yet")
      end
    end
  end
end
