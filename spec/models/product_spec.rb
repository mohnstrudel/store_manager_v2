# frozen_string_literal: true

# == Schema Information
#
# Table name: products
#
#  id           :bigint           not null, primary key
#  full_title   :string
#  image        :string
#  sku          :string
#  slug         :string
#  title        :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  franchise_id :bigint           not null
#  shape_id     :bigint           not null
#  shopify_id   :string
#  woo_id       :string
#
require "rails_helper"

RSpec.describe Product do
  describe "auditing" do
    it "is audited" do
      expect(described_class.auditing_enabled).to be true
    end
  end

  describe "#shopify_published?" do
    context "when product has not been published to Shopify" do
      it "returns false" do
        product = build(:product)
        # Create product without store_infos to simulate unpublished state
        product.save(validate: false)

        expect(product.shopify_published?).to be false
      end
    end

    context "when product has been published to Shopify" do
      it "returns true" do
        product = create(:product)

        expect(product.shopify_published?).to be true
      end
    end
  end

  describe "description field" do
    context "when product has a description" do
      it "stores HTML content" do
        html_description = "<p>This is a <strong>great</strong> product with <em>features</em>.</p>"
        product = create(:product, description: html_description)

        expect(product.description.body.to_html.strip).to eq(html_description)
      end

      it "allows updating description" do
        product = create(:product, description: "<p>Original description</p>")
        product.update(description: "<p>Updated <strong>description</strong></p>")

        expect(product.reload.description.body.to_html.strip).to eq("<p>Updated <strong>description</strong></p>")
      end
    end

    context "when product has no description" do
      it "allows creating product without description" do
        product = create(:product, description: nil)

        expect(product.description.body).to be_blank
      end

      it "allows empty string description" do
        product = create(:product, description: "")

        expect(product.description.body).to be_blank
      end
    end
  end

  describe "store_infos associations" do
    it "has many store_infos" do
      product = create(:product)
      shopify_info = product.store_infos.shopify.first
      woo_info = product.store_infos.woo.first

      expect(product.store_infos).to include(shopify_info, woo_info)
    end

    it "has one shopify_info" do
      product = create(:product)
      shopify_info = product.store_infos.shopify.first

      aggregate_failures do
        expect(product.shopify_info).to eq(shopify_info)
        expect(product.shopify_info.store_name).to eq("shopify")
      end
    end

    it "has one woo_info" do
      product = create(:product)
      woo_info = product.store_infos.woo.first

      aggregate_failures do
        expect(product.woo_info).to eq(woo_info)
        expect(product.woo_info.store_name).to eq("woo")
      end
    end

    it "destroys store_infos when product is destroyed" do
      product = create(:product)

      expect {
        product.destroy
      }.to change(StoreInfo, :count).by(-2)
    end

    it "removes the individual store_infos" do
      product = create(:product)

      product.destroy

      expect(StoreInfo.where(storable: product)).to be_empty
    end
  end

  describe "store_infos scoping" do
    it "returns shopify store_info through shopify_info association" do
      product = create(:product)

      aggregate_failures do
        expect(product.shopify_info).to be_a(StoreInfo)
        expect(product.shopify_info.store_name).to eq("shopify")
      end
    end

    it "returns woo store_info through woo_info association" do
      product = create(:product)

      aggregate_failures do
        expect(product.woo_info).to be_a(StoreInfo)
        expect(product.woo_info.store_name).to eq("woo")
      end
    end

    it "returns nil for shopify_info when not present" do
      product = create(:product)
      product.shopify_info.destroy

      expect(product.reload.shopify_info).to be_nil
    end

    it "returns nil for woo_info when not present" do
      product = create(:product)
      product.woo_info.destroy

      expect(product.reload.woo_info).to be_nil
    end
  end

  describe "store_infos uniqueness validation" do
    it "prevents duplicate store_name for the same product" do
      product = create(:product)

      expect {
        create(:store_info, :shopify, storable: product)
      }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it "allows same store_name for different products" do
      create(:product)
      product2 = create(:product)

      # Remove existing shopify store_info from product2 created by factory
      product2.store_infos.shopify.destroy_all

      expect {
        create(:store_info, :shopify, storable: product2)
      }.not_to raise_error
    end
  end
end
