# frozen_string_literal: true

require "rails_helper"

RSpec.describe Products::ShopifyPushesController do
  before { sign_in_as_admin }
  after { log_out }

  describe "POST #create" do
    context "when product is published to Shopify" do
      let(:product) { create(:product) }

      before do
        allow(Shopify::UpdateProductJob).to receive(:perform_later).with(product.id)
      end

      it "enqueues an update job" do
        post :create, params: {product_id: product.to_param}

        expect(Shopify::UpdateProductJob).to have_received(:perform_later).with(product.id)
      end

      it "redirects back to the product with notice", :aggregate_failures do
        post :create, params: {product_id: product.to_param}

        expect(response).to redirect_to(product_path(product))
        expect(flash[:notice]).to eq("Product is being pushed to Shopify")
      end
    end

    context "when product is not published to Shopify" do
      let(:product) do
        record = create(:product)
        record.shopify_info.update!(store_id: nil)
        record
      end

      before do
        allow(Shopify::CreateProductJob).to receive(:perform_later).with(product.id)
      end

      it "enqueues a create job" do
        post :create, params: {product_id: product.to_param}

        expect(Shopify::CreateProductJob).to have_received(:perform_later).with(product.id)
      end

      it "redirects back to the product with notice", :aggregate_failures do
        post :create, params: {product_id: product.to_param}

        expect(response).to redirect_to(product_path(product))
        expect(flash[:notice]).to eq("Product is being pushed to Shopify")
      end
    end
  end
end
