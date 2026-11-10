# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Products Sync API" do
  let(:product) { create(:product, :synced) }

  before do
    sign_in_as_admin
  end

  describe "POST /products/pull" do
    it "enqueues a full pull when no scope is given", :aggregate_failures do
      post products_pull_path

      expect(Shopify::PullProductsJob).to have_been_enqueued.with(changes_only: false, requested_by: admin)
      expect(response).to redirect_to(products_path)
      expect(flash[:notice]).to include(message: start_with("Started. You'll get a notification"))
    end

    it "enqueues a changes pull for scope=changes", :aggregate_failures do
      post products_pull_path(scope: "changes")

      expect(Shopify::PullProductsJob).to have_been_enqueued.with(changes_only: true, requested_by: admin)
      expect(response).to redirect_to(products_path)
      expect(flash[:notice]).to include(message: start_with("Started. You'll get a notification"))
    end

    it "pulls everything when only the retired limit param is sent" do
      post products_pull_path(limit: "100")

      expect(Shopify::PullProductsJob).to have_been_enqueued.with(changes_only: false, requested_by: admin)
    end

    it "leaves the stored sync time to the pull itself" do
      Config.update_shopify_products_sync_time(Time.utc(2026, 11, 10, 10))

      expect { post products_pull_path(scope: "changes") }.not_to change(Config, :shopify_products_sync_at)
    end
  end

  describe "POST /products/:product_id/shopify_pull" do
    context "when product is published to Shopify" do
      before do
        allow(Shopify::PullProductJob).to receive(:perform_later).with(product.shopify_info.store_id, requested_by: admin)
      end

      it "enqueues the Shopify pull product job" do
        post product_shopify_pull_path(product)

        expect(Shopify::PullProductJob).to have_received(:perform_later).with(product.shopify_info.store_id, requested_by: admin)
      end

      it "redirects to products path with notice", :aggregate_failures do # rubocop:todo RSpec/MultipleExpectations
        post product_shopify_pull_path(product)

        expect(response).to redirect_to(product_path(product))
        expect(flash[:notice]).to eq("Started pulling this product from Shopify. You'll get a notification when it finishes.")
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
        record = create(:product, :synced)
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

  describe "missing products" do
    before do
      allow(Shopify::PullProductJob).to receive(:perform_later)
      allow(Shopify::UpdateProductJob).to receive(:perform_later)
      allow(Shopify::CreateProductJob).to receive(:perform_later)
    end

    it "returns 404 and enqueues nothing when pulling a product that does not exist", :aggregate_failures do
      post product_shopify_pull_path(0)

      expect(response).to have_http_status(:not_found)
      expect(Shopify::PullProductJob).not_to have_received(:perform_later)
    end

    it "returns 404 and enqueues nothing when pushing a product that does not exist", :aggregate_failures do
      post product_shopify_push_path(0)

      expect(response).to have_http_status(:not_found)
      expect(Shopify::UpdateProductJob).not_to have_received(:perform_later)
      expect(Shopify::CreateProductJob).not_to have_received(:perform_later)
    end
  end
end
