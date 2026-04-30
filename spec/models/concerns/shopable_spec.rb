# frozen_string_literal: true

require "rails_helper"

RSpec.describe Shopable do
  describe "associations added when included" do
    let(:product) { create(:product) }

    it "adds store_infos association" do
      expect(product).to respond_to(:store_infos)
    end

    it "adds shopify_info association" do
      expect(product).to respond_to(:shopify_info)
    end

    it "adds woo_info association" do
      expect(product).to respond_to(:woo_info)
    end
  end

  describe ".find_by_shopify_id" do
    let(:product) { create(:product) }

    context "when store info exists" do
      before do
        product.shopify_info.update!(store_id: "gid://shopify/Product/12345")
      end

      it "finds the record by Shopify store_id" do
        expect(Product.find_by_shopify_id("gid://shopify/Product/12345")).to eq(product)
      end
    end

    context "when store info does not exist" do
      it "returns nil" do
        expect(Product.find_by_shopify_id("gid://shopify/Product/99999")).to be_nil
      end
    end

    context "when store_id is blank" do
      it "returns nil", :aggregate_failures do
        expect(Product.find_by_shopify_id(nil)).to be_nil
        expect(Product.find_by_shopify_id("")).to be_nil
      end
    end

    context "when store_id belongs to different storable_type" do
      let(:variant) { create(:variant) }

      before do
        variant.shopify_info.update!(store_id: "gid://shopify/Product/12345")
      end

      it "does not find the record" do
        expect(Product.find_by_shopify_id("gid://shopify/Product/12345")).to be_nil
      end
    end
  end

  describe ".find_by_woo_id" do
    let(:product) { create(:product) }

    context "when store info exists" do
      before do
        product.woo_info.update!(store_id: "woo_product_123")
      end

      it "finds the record by Woo store_id" do
        expect(Product.find_by_woo_id("woo_product_123")).to eq(product)
      end
    end

    context "when store info does not exist" do
      it "returns nil" do
        expect(Product.find_by_woo_id("woo_product_99999")).to be_nil
      end
    end

    context "when store_id is blank" do
      it "returns nil", :aggregate_failures do
        expect(Product.find_by_woo_id(nil)).to be_nil
        expect(Product.find_by_woo_id("")).to be_nil
      end
    end
  end

  describe "#shopify_linked?" do
    context "when shopify_info has store_id" do
      let(:product) { create(:product) }

      before do
        product.shopify_info.update!(store_id: "gid://shopify/Product/12345")
      end

      it "returns true" do
        expect(product.shopify_linked?).to be true
      end
    end

    context "when shopify_info exists but has no store_id" do
      let(:product) { create(:product) }

      before do
        product.shopify_info.update!(store_id: nil)
      end

      it "returns false" do
        expect(product.shopify_linked?).to be false
      end
    end

    context "when shopify_info is nil" do
      let(:product) { create(:product) }

      before do
        product.shopify_info.destroy
        product.reload
      end

      it "returns false", :aggregate_failures do
        # After destroy and reload, shopify_info should be nil
        # since has_one associations don't auto-create
        expect(product.shopify_info).to be_nil
        expect(product.shopify_linked?).to be false
      end
    end
  end
end
