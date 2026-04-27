# frozen_string_literal: true

require "rails_helper"

RSpec.describe StoreInfo::References do
  describe "#product_url" do
    it "builds a Shopify product URL from the default slug" do
      store_info = build(:store_info, :shopify, :with_slug)

      expect(store_info.product_url).to eq("https://handsomecake.com/products/test-product")
    end

    it "builds a Woo product URL from a custom handle" do
      store_info = build(:store_info, :woo, :with_slug)

      expect(store_info.product_url("custom-handle")).to eq("https://store.handsomecake.com/product/custom-handle")
    end

    it "returns a stored Woo permalink as-is" do
      store_info = build(:store_info, :woo, slug: "https://store.handsomecake.com/product/test-product/")

      expect(store_info.product_url).to eq("https://store.handsomecake.com/product/test-product/")
    end
  end

  describe "#id_short" do
    it "returns nil when store_id is blank" do
      store_info = build(:store_info, :shopify, storable: build(:product), store_id: nil)

      expect(store_info.id_short).to be_nil
    end

    it "strips Shopify product gid prefix for Product storables" do
      store_info = build(:store_info, :shopify, storable: build(:product), store_id: "gid://shopify/Product/12345")

      expect(store_info.id_short).to eq("12345")
    end

    it "strips Shopify order gid prefix for Sale storables" do
      store_info = build(:store_info, :shopify, storable: build(:sale), store_id: "gid://shopify/Order/777")

      expect(store_info.id_short).to eq("777")
    end

    it "strips Shopify product-variant gid prefix for Edition storables" do
      store_info = build(:store_info, :shopify, storable: build(:edition), store_id: "gid://shopify/ProductVariant/888")

      expect(store_info.id_short).to eq("888")
    end
  end
end
