# frozen_string_literal: true

require "rails_helper"

RSpec.describe GalleryHelper do
  describe "#gallery_items_for" do
    it "builds gallery item data for attached images" do
      product = create(:product)
      media = create(:media, :for_product, mediaable: product, alt: "Front view")

      items = helper.gallery_items_for([media])

      aggregate_failures do
        expect(items.size).to eq(1)
        expect(items.first[:alt]).to eq("Front view")
        expect(items.first[:thumb_src]).to include("/rails/active_storage/representations/")
        expect(items.first[:main_src]).to include("/rails/active_storage/representations/")
      end
    end

    it "skips media without attached images" do
      product = create(:product)
      media = create(:media, :for_product, mediaable: product)
      media.image.purge

      expect(helper.gallery_items_for([media])).to eq([])
    end
  end
end
