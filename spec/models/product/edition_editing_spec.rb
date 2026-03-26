# frozen_string_literal: true

require "rails_helper"

RSpec.describe Product do
  describe "#apply_editions_attributes!" do
    let(:product) { create(:product) }

    it "updates an existing edition" do
      edition = create(:edition, product:, sku: "OLD-SKU")

      product.apply_editions_attributes!([
        {id: edition.id, sku: "NEW-SKU"}
      ])

      expect(edition.reload.sku).to eq("NEW-SKU")
    end

    it "raises a product validation error for a duplicate combination" do
      size = create(:size)
      version = create(:version)
      color = create(:color)
      create(:edition, product:, size:, version:, color:)

      expect {
        product.apply_editions_attributes!([
          {size_id: size.id, version_id: version.id, color_id: color.id}
        ])
      }.to raise_error(ActiveRecord::RecordInvalid, /Combination/)

      expect(product.errors[:editions].first).to match(/Combination/)
    end

    it "deactivates an edition with sale history instead of destroying it" do
      edition = create(:edition, product:)
      sale = create(:sale)
      create(:sale_item, product:, edition:, sale:, qty: 1)

      expect {
        product.apply_editions_attributes!([
          {id: edition.id, destroy: true}
        ])
      }.not_to change(Edition, :count)

      expect(edition.reload.deactivated_at).to be_present
    end
  end
end
