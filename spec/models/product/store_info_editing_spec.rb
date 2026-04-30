# frozen_string_literal: true

require "rails_helper"

# rubocop:todo RSpec/SpecFilePathFormat
RSpec.describe Product do
  describe "#save_editing!" do
    let(:product) { create(:product) }

    it "updates an existing store info" do
      shopify_info = product.store_infos.shopify.first

      product.save_editing!(
        product_attributes: editing_product_attributes(product),
        variants_attributes: [],
        store_infos_attributes: [
          {id: shopify_info.id, tag_list: "featured"}
        ],
        media_attributes: [],
        new_media_images: []
      )

      expect(shopify_info.reload.tag_list).to eq(["featured"])
    end

    it "creates a new store info when id is blank" do # rubocop:todo RSpec/MultipleExpectations
      product.store_infos.reload.destroy_all

      expect {
        product.save_editing!(
          product_attributes: editing_product_attributes(product),
          variants_attributes: [],
          store_infos_attributes: [
            {store_name: "shopify", tag_list: "new-store"}
          ],
          media_attributes: [],
          new_media_images: []
        )
      }.to change(product.store_infos, :count).by(1)

      expect(product.reload.store_infos.shopify.first.tag_list).to eq(["new-store"])
    end

    it "destroys a store info when marked for destruction" do # rubocop:todo RSpec/MultipleExpectations
      woo_info = product.store_infos.woo.first

      expect {
        product.save_editing!(
          product_attributes: editing_product_attributes(product),
          variants_attributes: [],
          store_infos_attributes: [
            {id: woo_info.id, destroy: true}
          ],
          media_attributes: [],
          new_media_images: []
        )
      }.to change(product.store_infos, :count).by(-1)

      expect(product.reload.woo_info).to be_nil
    end

    it "raises a product validation error for duplicate store connections" do # rubocop:todo RSpec/MultipleExpectations
      shopify_info = product.store_infos.shopify.first

      expect {
        product.save_editing!(
          product_attributes: editing_product_attributes(product),
          variants_attributes: [],
          store_infos_attributes: [
            {id: shopify_info.id, store_name: "woo"}
          ],
          media_attributes: [],
          new_media_images: []
        )
      }.to raise_error(ActiveRecord::RecordInvalid)

      editing_store_info = product.store_infos.find { |store_info| store_info.id == shopify_info.id }
      expect(editing_store_info.errors[:store_name]).to include("has already been taken")
    end

    def editing_product_attributes(product)
      {
        title: product.title,
        franchise_id: product.franchise_id,
        shape: product.shape
      }
    end
  end
end
# rubocop:enable RSpec/SpecFilePathFormat
