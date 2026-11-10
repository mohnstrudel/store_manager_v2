# frozen_string_literal: true

require "rails_helper"

RSpec.describe Product do
  describe ".listed" do
    it "sorts published products before unpublished, then by created_at desc" do
      unpublished_newer = create(:product)
      unpublished_older = create(:product, created_at: 1.day.ago)
      published = create(:product, published_at: 1.week.ago)

      relation = described_class.listed.where(id: [unpublished_newer.id, unpublished_older.id, published.id]).to_a

      expect(relation.map(&:id)).to eq([published.id, unpublished_newer.id, unpublished_older.id])
    end

    it "eager loads the listing associations" do
      product = create(:product, published_at: 1.day.ago)

      relation = described_class.listed.where(id: product.id).to_a

      aggregate_failures do
        expect(relation.first.association(:shopify_info).loaded?).to be true
        expect(relation.first.association(:woo_info).loaded?).to be true
        expect(relation.first.association(:variants).loaded?).to be true
      end
    end
  end

  describe ".preloaded" do
    it "eager loads product detail associations" do
      product = create(:product)
      product.brands << create(:brand)
      product.sizes << create(:size)
      product.versions << create(:version)
      product.colors << create(:color)
      product.update!(description: "<p>Product description</p>")
      create(:purchase, product:)

      relation = described_class.preloaded.where(id: product.id).to_a

      aggregate_failures do
        expect(relation).to include(product)
        expect(relation.first.association(:franchise)).to be_loaded
        expect(relation.first.association(:shopify_info)).to be_loaded
        expect(relation.first.association(:woo_info)).to be_loaded
        expect(relation.first.association(:brands)).to be_loaded
        expect(relation.first.association(:sizes)).to be_loaded
        expect(relation.first.association(:versions)).to be_loaded
        expect(relation.first.association(:colors)).to be_loaded
        expect(relation.first.association(:rich_text_description)).to be_loaded
        expect(relation.first.association(:purchases).loaded?).to be true
        expect(relation.first.association(:purchase_items).loaded?).to be true
        expect(relation.first.association(:store_infos).loaded?).to be true
      end
    end
  end
end
