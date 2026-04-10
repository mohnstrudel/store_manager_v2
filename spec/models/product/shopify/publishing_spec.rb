# frozen_string_literal: true

require "rails_helper"

RSpec.describe Product::Shopify::Publishing do
  describe "#publish_on_shopify!" do
    let(:product) do
      create(:product_with_brands).tap do |created_product|
        created_product.store_infos.destroy_all
      end
    end
    let(:store_id) { "gid://shopify/Product/12345" }
    let(:slug) { "test-product" }

    it "creates a Shopify store info when missing" do
      expect {
        product.publish_on_shopify!(store_id:, slug:)
      }.to change { product.store_infos.shopify.count }.by(1)
    end

    it "stores the Shopify product ID" do
      store_info = product.publish_on_shopify!(store_id:, slug:)

      expect(store_info.store_id).to eq("gid://shopify/Product/12345")
    end

    it "stores the product slug" do
      store_info = product.publish_on_shopify!(store_id:, slug:)

      expect(store_info.slug).to eq("test-product")
    end

    it "sets the push time" do
      before_time = Time.current

      store_info = product.publish_on_shopify!(store_id:, slug:)

      expect(store_info.push_time).to be_between(before_time, Time.current).inclusive
    end

    context "when Shopify store info already exists" do
      let(:product) { create(:product_with_brands) }
      let!(:existing_store_info) do
        product.shopify_info.tap do |store_info|
          store_info.update!(store_id: "old-id", slug: "old-handle")
        end
      end

      it "updates the existing Shopify store info" do
        expect {
          product.publish_on_shopify!(store_id:, slug:)
        }.not_to change { product.store_infos.shopify.count }

        expect(existing_store_info.reload.store_id).to eq("gid://shopify/Product/12345")
      end
    end

    context "when store_id is blank" do
      it "raises an error" do
        expect {
          product.publish_on_shopify!(store_id: nil, slug:)
        }.to raise_error(ArgumentError, "Store ID cannot be blank")
      end
    end
  end
end
