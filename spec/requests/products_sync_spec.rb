# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Products Sync API" do
  let(:product) { create(:product) }

  before do
    sign_in_as_admin
  end

  describe "GET /products/pull" do
    context "with limit parameter" do
      it "converts string limit to integer before enqueuing job" do
        allow(Shopify::PullProductsJob).to receive(:perform_later).with(limit: 50)
        allow(Config).to receive(:update_shopify_products_sync_time)

        get pull_products_path(limit: "50")

        expect(Shopify::PullProductsJob).to have_received(:perform_later).with(limit: 50)
        expect(response).to redirect_to(products_path)
        expect(flash[:notice]).to include("Success! Visit")
      end
    end

    context "without limit parameter" do
      it "enqueues job with nil limit" do
        allow(Shopify::PullProductsJob).to receive(:perform_later).with(limit: nil)
        allow(Config).to receive(:update_shopify_products_sync_time)

        get pull_products_path

        expect(Shopify::PullProductsJob).to have_received(:perform_later).with(limit: nil)
        expect(response).to redirect_to(products_path)
        expect(flash[:notice]).to include("Success! Visit")
      end
    end
  end

  describe "POST /products/:id/publish_to_shopify" do
    context "when product is not published to Shopify" do
      before do
        allow(Shopify::CreateProductJob).to receive(:perform_later).with(product.id)
      end

      it "enqueues the Shopify create product job" do
        post publish_to_shopify_product_path(product)

        expect(Shopify::CreateProductJob).to have_received(:perform_later).with(product.id)
      end

      it "redirects to products path with notice", :aggregate_failures do # rubocop:todo RSpec/MultipleExpectations
        post publish_to_shopify_product_path(product)

        expect(response).to redirect_to(products_path)
        expect(flash[:notice]).to eq("Product is being published to Shopify")
      end
    end
  end

  describe "POST /products/:id/push_to_shopify" do
    context "when product is already published to Shopify" do
      before do
        allow(Shopify::UpdateProductJob).to receive(:perform_later).with(product.id)
      end

      it "enqueues the Shopify update product job" do
        post push_to_shopify_product_path(product)

        expect(Shopify::UpdateProductJob).to have_received(:perform_later).with(product.id)
      end

      it "redirects to products path with notice", :aggregate_failures do # rubocop:todo RSpec/MultipleExpectations
        post push_to_shopify_product_path(product)

        expect(response).to redirect_to(products_path)
        expect(flash[:notice]).to eq("Product updates are being pushed to Shopify")
      end
    end
  end

  describe "POST /products/:id/pull_from_shopify" do
    context "when product is published to Shopify" do
      before do
        allow(Shopify::PullProductJob).to receive(:perform_later).with(product.shopify_info.store_id)
      end

      it "enqueues the Shopify pull product job" do
        post pull_from_shopify_product_path(product)

        expect(Shopify::PullProductJob).to have_received(:perform_later).with(product.shopify_info.store_id)
      end

      it "redirects to products path with notice", :aggregate_failures do # rubocop:todo RSpec/MultipleExpectations
        post pull_from_shopify_product_path(product)

        expect(response).to redirect_to(products_path)
        expect(flash[:notice]).to eq("Product is being pulled from Shopify")
      end
    end

    context "when product is not published to Shopify" do
      let(:unpublished_product) do
        product = build(:product)
        product.save(validate: false)
        product
      end

      before do
        allow(Shopify::PullProductJob).to receive(:perform_later)
      end

      it "does not enqueue any job" do
        post pull_from_shopify_product_path(unpublished_product)

        expect(Shopify::PullProductJob).not_to have_received(:perform_later)
      end

      it "redirects to products path with notice about not being published", :aggregate_failures do # rubocop:todo RSpec/MultipleExpectations
        post pull_from_shopify_product_path(unpublished_product)

        expect(response).to redirect_to(products_path)
        expect(flash[:notice]).to eq("Product has not been published to Shopify yet")
      end
    end
  end
end
