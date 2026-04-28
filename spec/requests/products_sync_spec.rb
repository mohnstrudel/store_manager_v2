# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Products Sync API" do
  let(:product) { create(:product) }

  before do
    sign_in_as_admin
  end

  describe "POST /products/pull" do
    context "with limit parameter" do
      it "converts string limit to integer before enqueuing job", :aggregate_failures do
        allow(Shopify::PullProductsJob).to receive(:perform_later).with(limit: 100)
        allow(Config).to receive(:update_shopify_products_sync_time)

        post products_pull_path(limit: "100")

        expect(Shopify::PullProductsJob).to have_received(:perform_later).with(limit: 100)
        expect(response).to redirect_to(products_path)
        expect(flash[:notice]).to include("Success! Visit")
      end
    end

    context "without limit parameter" do
      it "enqueues job with nil limit", :aggregate_failures do
        allow(Shopify::PullProductsJob).to receive(:perform_later).with(limit: nil)
        allow(Config).to receive(:update_shopify_products_sync_time)

        post products_pull_path

        expect(Shopify::PullProductsJob).to have_received(:perform_later).with(limit: nil)
        expect(response).to redirect_to(products_path)
        expect(flash[:notice]).to include("Success! Visit")
      end
    end
  end

  describe "POST /products/:product_id/shopify_pull" do
    context "when product is published to Shopify" do
      before do
        allow(Shopify::PullProductJob).to receive(:perform_later).with(product.shopify_info.store_id)
      end

      it "enqueues the Shopify pull product job" do
        post product_shopify_pull_path(product)

        expect(Shopify::PullProductJob).to have_received(:perform_later).with(product.shopify_info.store_id)
      end

      it "redirects to products path with notice", :aggregate_failures do # rubocop:todo RSpec/MultipleExpectations
        post product_shopify_pull_path(product)

        expect(response).to redirect_to(product_path(product))
        expect(flash[:notice]).to eq("Product is being fetched from Shopify")
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
        post product_shopify_pull_path(unpublished_product)

        expect(Shopify::PullProductJob).not_to have_received(:perform_later)
      end

      it "redirects to products path with notice about not being published", :aggregate_failures do # rubocop:todo RSpec/MultipleExpectations
        post product_shopify_pull_path(unpublished_product)

        expect(response).to redirect_to(product_path(unpublished_product))
        expect(flash[:notice]).to eq("Product has not been published to Shopify yet")
      end
    end
  end

  describe "POST /products/:product_id/shopify_push" do
    context "when product is published to Shopify" do
      before do
        allow(Shopify::UpdateProductJob).to receive(:perform_later).with(product.id)
      end

      it "enqueues the Shopify update product job" do
        post product_shopify_push_path(product)

        expect(Shopify::UpdateProductJob).to have_received(:perform_later).with(product.id)
      end

      it "redirects to the product with notice", :aggregate_failures do
        post product_shopify_push_path(product)

        expect(response).to redirect_to(product_path(product))
        expect(flash[:notice]).to eq("Product is being pushed to Shopify")
      end
    end

    context "when product is not published to Shopify" do
      let(:unpublished_product) do
        record = create(:product)
        record.shopify_info.update!(store_id: nil)
        record
      end

      before do
        allow(Shopify::CreateProductJob).to receive(:perform_later).with(unpublished_product.id)
      end

      it "enqueues the Shopify create product job" do
        post product_shopify_push_path(unpublished_product)

        expect(Shopify::CreateProductJob).to have_received(:perform_later).with(unpublished_product.id)
      end

      it "redirects to the product with notice", :aggregate_failures do
        post product_shopify_push_path(unpublished_product)

        expect(response).to redirect_to(product_path(unpublished_product))
        expect(flash[:notice]).to eq("Product is being pushed to Shopify")
      end
    end
  end
end
