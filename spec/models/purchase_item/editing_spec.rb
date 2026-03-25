# frozen_string_literal: true

require "rails_helper"

RSpec.describe PurchaseItem do
  def uploaded_test_image(filename: "test.jpg", content_type: "image/jpeg")
    tempfile = Tempfile.new(["test", ".jpg"])
    tempfile.binmode
    tempfile.write("\xFF\xD8\xFF\xE0\x00\x10JFIF\x00\x01\x01\x00\x00\x01\x00\x01\x00\x00\xFF\xD9")
    tempfile.rewind

    Rack::Test::UploadedFile.new(tempfile.path, content_type, original_filename: filename)
  end

  describe "#create_from_form!" do
    let(:purchase) { create(:purchase) }
    let(:warehouse) { create(:warehouse) }
    let(:purchase_item) { described_class.new }

    it "creates the purchase item and adds new media" do
      expect {
        purchase_item.create_from_form!(
          {
            purchase_id: purchase.id,
            warehouse_id: warehouse.id,
            weight: 2
          },
          new_media_images: [uploaded_test_image]
        )
      }.to change(Media, :count).by(1)

      aggregate_failures do
        expect(purchase_item).to be_persisted
        expect(purchase_item.purchase).to eq(purchase)
        expect(purchase_item.warehouse).to eq(warehouse)
        expect(purchase_item.media.count).to eq(1)
      end
    end
  end

  describe "#apply_form_changes!" do
    let(:purchase_item) { create(:purchase_item, weight: 1) }

    it "updates attributes and media together" do
      media_item = create(:media, :for_purchase_item, mediaable: purchase_item, alt: "Old")

      purchase_item.apply_form_changes!(
        attributes: {weight: 5},
        media_attributes: [{id: media_item.id, alt: "Updated"}],
        new_media_images: []
      )

      aggregate_failures do
        expect(purchase_item.reload.weight).to eq(5)
        expect(media_item.reload.alt).to eq("Updated")
      end
    end
  end
end
