# frozen_string_literal: true

require "rails_helper"

RSpec.describe Product do
  describe "#apply_store_info_attributes!" do
    let(:product) { create(:product) }

    it "updates an existing store info" do
      shopify_info = product.store_infos.shopify.first

      product.apply_store_info_attributes!([
        {id: shopify_info.id, tag_list: "featured"}
      ])

      expect(shopify_info.reload.tag_list).to eq(["featured"])
    end

    it "creates a new store info when id is blank" do
      product.store_infos.destroy_all

      expect {
        product.apply_store_info_attributes!([
          {store_name: "shopify", tag_list: "new-store"}
        ])
      }.to change(product.store_infos, :count).by(1)

      expect(product.reload.store_infos.shopify.first.tag_list).to eq(["new-store"])
    end

    it "destroys a store info when marked for destruction" do
      woo_info = product.store_infos.woo.first

      expect {
        product.apply_store_info_attributes!([
          {id: woo_info.id, destroy: true}
        ])
      }.to change(product.store_infos, :count).by(-1)

      expect(product.reload.woo_info).to be_nil
    end
  end
end
