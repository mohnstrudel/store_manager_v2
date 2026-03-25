# frozen_string_literal: true

require "rails_helper"

RSpec.describe Warehouse do
  def uploaded_test_image(filename: "test.jpg", content_type: "image/jpeg")
    tempfile = Tempfile.new(["test", ".jpg"])
    tempfile.binmode
    tempfile.write("\xFF\xD8\xFF\xE0\x00\x10JFIF\x00\x01\x01\x00\x00\x01\x00\x01\x00\x00\xFF\xD9")
    tempfile.rewind

    Rack::Test::UploadedFile.new(tempfile.path, content_type, original_filename: filename)
  end

  describe "#add_new_media_from_form!" do
    let(:warehouse) { create(:warehouse) }

    it "creates media records for valid uploads" do
      expect {
        warehouse.add_new_media_from_form!([
          uploaded_test_image,
          uploaded_test_image(filename: "second.jpg")
        ])
      }.to change(warehouse.media, :count).by(2)

      expect(warehouse.media.ordered.pluck(:position)).to eq([0, 1])
    end
  end

  describe "#update_media_from_form!" do
    let(:warehouse) { create(:warehouse) }
    let!(:media_item) { create(:media, :for_warehouse, mediaable: warehouse, position: 0, alt: "Original") }

    it "updates alt and position" do
      warehouse.update_media_from_form!([
        {id: media_item.id, alt: "Updated", position: 5}
      ])

      aggregate_failures do
        expect(media_item.reload.alt).to eq("Updated")
        expect(media_item.position).to eq(5)
      end
    end

    it "ignores unknown media ids" do
      expect {
        warehouse.update_media_from_form!([
          {id: 999_999, alt: "Missing"}
        ])
      }.not_to raise_error

      expect(media_item.reload.alt).to eq("Original")
    end
  end
end
