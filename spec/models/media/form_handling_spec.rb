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

      aggregate_failures do
        expect(warehouse.media.ordered.pluck(:position)).to eq([0, 1])
        expect(warehouse.media.ordered.all? { |media_item| media_item.image.attached? }).to be(true)
      end
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

    it "loads submitted media in one owner-scoped query" do
      second = create(:media, :for_warehouse, mediaable: warehouse, position: 1)
      third = create(:media, :for_warehouse, mediaable: warehouse, position: 2)
      lookups = []
      subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |_name, _started, _finished, _id, payload|
        sql = payload[:sql]
        lookups << sql if sql.start_with?('SELECT "media".* FROM "media"') && sql.include?('"media"."id"')
      end

      begin
        warehouse.update_media_from_form!([
          {id: media_item.id, alt: "First"},
          {id: second.id, alt: "Second"},
          {id: third.id, alt: "Third"}
        ])
      ensure
        ActiveSupport::Notifications.unsubscribe(subscriber)
      end

      expect(lookups.size).to eq(1)
      expect([media_item, second, third].map { |item| item.reload.alt }).to eq(%w[First Second Third])
    end

    it "ignores foreign media and repeated ids after destruction" do
      foreign_media = create(:media, :for_warehouse, mediaable: create(:warehouse), alt: "Foreign")

      warehouse.update_media_from_form!([
        {id: media_item.id, _destroy: true},
        {id: media_item.id, alt: "Restored"},
        {id: foreign_media.id, alt: "Changed"}
      ])

      expect(Media.exists?(media_item.id)).to be(false)
      expect(foreign_media.reload.alt).to eq("Foreign")
    end
  end
end
