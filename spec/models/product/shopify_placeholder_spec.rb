# frozen_string_literal: true

require "rails_helper"

RSpec.describe Product, ".find_or_create_shopify_placeholder!" do
  describe ".find_or_create_shopify_placeholder!" do
    let(:store_id) { "gid://shopify/Product/123456789" }

    it "creates a distinct placeholder product for the Shopify store id" do
      product = described_class.find_or_create_shopify_placeholder!(store_id:)

      expect(product).to be_persisted
      expect(product.shopify_info.store_id).to eq(store_id)
      expect(product.title).to include("[BROKEN SHOPIFY PRODUCT]")
      expect(product.base_edition.sku).to start_with("broken-shopify-")
      expect(product.franchise.title).to eq("Broken Shopify Products")
      expect(product.shape.title).to eq("Unknown Shopify Shape")
    end

    it "reuses the same placeholder on repeated calls" do
      first_product = described_class.find_or_create_shopify_placeholder!(store_id:)
      second_product = described_class.find_or_create_shopify_placeholder!(store_id:)

      expect(second_product).to eq(first_product)
      expect(Product.where(id: first_product.id).count).to eq(1)
    end
  end
end
