# frozen_string_literal: true

require "rails_helper"

RSpec.describe Product::Shopify::Matching do
  describe ".find_storeless_match_for_shopify" do
    let(:identity) do
      {
        franchise_title: "Mortal Kombat",
        product_title: "Mileena",
        shape_title: "Statue",
        size_values: "1:4",
        brand_titles: "Outworld Creations"
      }
    end

    def create_storeless_product(title:, franchise_title:, shape_title:, size_values: [], brand_titles: [])
      product = create(:product, title: title, franchise: create(:franchise, title: franchise_title), shape: shape_title)
      product.store_infos.destroy_all
      product.update_columns(shopify_id: nil, woo_id: nil)
      product.reload

      size_values.each { |value| product.sizes << Size.find_or_create_by!(value:) }
      brand_titles.each { |title| product.brands << Brand.find_or_create_by!(title:) }

      product
    end

    it "reuses the oldest storeless product with an exact parsed identity match" do
      oldest = create_storeless_product(
        title: "Mileena",
        franchise_title: "Mortal Kombat",
        shape_title: "Statue",
        size_values: ["1:4"],
        brand_titles: ["Outworld Creations"]
      )
      create_storeless_product(
        title: "Mileena",
        franchise_title: "Mortal Kombat",
        shape_title: "Statue",
        size_values: ["1:4"],
        brand_titles: ["Outworld Creations"]
      )

      expect(Product.find_storeless_match_for_shopify(**identity)).to eq(oldest)
    end

    it "does not match products with a different brand" do
      create_storeless_product(
        title: "Mileena",
        franchise_title: "Mortal Kombat",
        shape_title: "Statue",
        size_values: ["1:4"],
        brand_titles: ["Different Brand"]
      )

      expect(Product.find_storeless_match_for_shopify(**identity)).to be_nil
    end

    it "does not match products with a different size" do
      create_storeless_product(
        title: "Mileena",
        franchise_title: "Mortal Kombat",
        shape_title: "Statue",
        size_values: ["1:6"],
        brand_titles: ["Outworld Creations"]
      )

      expect(Product.find_storeless_match_for_shopify(**identity)).to be_nil
    end

    it "does not match products with a different franchise" do
      create_storeless_product(
        title: "Mileena",
        franchise_title: "Street Fighter",
        shape_title: "Statue",
        size_values: ["1:4"],
        brand_titles: ["Outworld Creations"]
      )

      expect(Product.find_storeless_match_for_shopify(**identity)).to be_nil
    end

    it "does not match products with a different shape" do
      create_storeless_product(
        title: "Mileena",
        franchise_title: "Mortal Kombat",
        shape_title: "Bust",
        size_values: ["1:4"],
        brand_titles: ["Outworld Creations"]
      )

      expect(Product.find_storeless_match_for_shopify(**identity)).to be_nil
    end

    it "does not match products that already have Shopify linkage" do
      linked_product = create_storeless_product(
        title: "Mileena",
        franchise_title: "Mortal Kombat",
        shape_title: "Statue",
        size_values: ["1:4"],
        brand_titles: ["Outworld Creations"]
      )
      linked_product.store_infos.create!(store_name: :shopify, store_id: "gid://shopify/Product/123")

      expect(Product.find_storeless_match_for_shopify(**identity)).to be_nil
    end

    it "still matches products that already have Woo linkage" do
      linked_product = create_storeless_product(
        title: "Mileena",
        franchise_title: "Mortal Kombat",
        shape_title: "Statue",
        size_values: ["1:4"],
        brand_titles: ["Outworld Creations"]
      )
      linked_product.store_infos.create!(store_name: :woo, store_id: "gid://woo/Product/123")

      expect(Product.find_storeless_match_for_shopify(**identity)).to eq(linked_product)
    end

    it "matches products when optional brand and size are blank on both sides" do
      product = create_storeless_product(
        title: "Mileena",
        franchise_title: "Mortal Kombat",
        shape_title: "Statue"
      )

      expect(
        Product.find_storeless_match_for_shopify(
          franchise_title: "Mortal Kombat",
          product_title: "Mileena",
          shape_title: "Statue",
          brand_titles: nil,
          size_values: nil
        )
      ).to eq(product)
    end
  end
end
