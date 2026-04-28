# frozen_string_literal: true

require "rails_helper"

# rubocop:todo RSpec/SpecFilePathFormat
RSpec.describe Product do
  describe "#save_editing!" do
    let(:product) { create(:product) }

    it "updates an existing variant" do
      variant = create(:variant, product:, sku: "OLD-SKU")

      product.save_editing!(
        product_attributes: editing_product_attributes(product),
        variants_attributes: [
          {id: variant.id, sku: "NEW-SKU"}
        ],
        store_infos_attributes: [],
        media_attributes: [],
        new_media_images: []
      )

      expect(variant.reload.sku).to eq("NEW-SKU")
    end

    it "raises a product validation error for a duplicate combination" do # rubocop:todo RSpec/MultipleExpectations
      size = create(:size)
      version = create(:version)
      color = create(:color)
      create(:variant, product:, size:, version:, color:)

      expect {
        product.save_editing!(
          product_attributes: editing_product_attributes(product),
          variants_attributes: [
            {size_id: size.id, version_id: version.id, color_id: color.id}
          ],
          store_infos_attributes: [],
          media_attributes: [],
          new_media_images: []
        )
      }.to raise_error(ActiveRecord::RecordInvalid)

      expect(product.variants.find(&:new_record?).errors[:base]).to include("Combination already exists")
    end

    it "raises a product validation error for a duplicate sku" do # rubocop:todo RSpec/MultipleExpectations
      create(:variant, product:, sku: "EXISTING-SKU")

      expect {
        product.save_editing!(
          product_attributes: editing_product_attributes(product),
          variants_attributes: [
            {sku: "EXISTING-SKU"}
          ],
          store_infos_attributes: [],
          media_attributes: [],
          new_media_images: []
        )
      }.to raise_error(ActiveRecord::RecordInvalid)

      expect(product.variants.find(&:new_record?).errors[:sku]).to include("has already been taken")
    end

    it "raises a product validation error when another product already uses the sku" do # rubocop:todo RSpec/MultipleExpectations
      create(:variant, sku: "GLOBAL-SKU")

      expect {
        product.save_editing!(
          product_attributes: editing_product_attributes(product),
          variants_attributes: [
            {sku: "GLOBAL-SKU"}
          ],
          store_infos_attributes: [],
          media_attributes: [],
          new_media_images: []
        )
      }.to raise_error(ActiveRecord::RecordInvalid)

      expect(product.variants.find(&:new_record?).errors[:sku]).to include("has already been taken")
    end

    it "deactivates a variant with sale history instead of destroying it" do # rubocop:todo RSpec/MultipleExpectations
      variant = create(:variant, product:)
      sale = create(:sale)
      create(:sale_item, product:, variant:, sale:, qty: 1)

      expect {
        product.save_editing!(
          product_attributes: editing_product_attributes(product),
          variants_attributes: [
            {id: variant.id, destroy: true}
          ],
          store_infos_attributes: [],
          media_attributes: [],
          new_media_images: []
        )
      }.not_to change(Variant, :count)

      expect(variant.reload.deactivated_at).to be_present
      expect(product.base_variant).to be_present
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
