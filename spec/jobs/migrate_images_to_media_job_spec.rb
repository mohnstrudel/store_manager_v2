# frozen_string_literal: true

require "rails_helper"

RSpec.describe MigrateImagesToMediaJob do
  include ActiveJob::TestHelper

  before do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  describe "#perform" do
    context "with a product having images" do
      let(:product) { create(:product) }
      let(:image_blob) do
        ActiveStorage::Blob.create_and_upload!(
          io: StringIO.new("test image content"),
          filename: "test.jpg",
          content_type: "image/jpeg"
        )
      end

      before do
        product.images.attach(image_blob)
      end

      it "creates a media record with the image attached" do
        expect { perform_job }.to change { product.media.count }.by(1)
      end

      it "points the media image to the same blob as the original image" do
        perform_job

        media = product.media.first
        expect(media.image.blob_id).to eq(product.images.first.blob_id)
      end

      it "preserves blob metadata (filename, content_type, byte_size, checksum)", :aggregate_failures do # rubocop:todo RSpec/MultipleExpectations
        perform_job

        media = product.media.first
        original_blob = product.images.first.blob

        expect(media.image.filename.to_s).to eq(original_blob.filename.to_s)
        expect(media.image.content_type).to eq(original_blob.content_type)
        expect(media.image.byte_size).to eq(original_blob.byte_size)
        expect(media.image.checksum).to eq(original_blob.checksum)
      end

      it "preserves the original image attachment" do
        expect { perform_job }.not_to change { product.images.count }
      end

      it "allows variants to be accessed after migration" do
        perform_job

        media = product.media.first

        %i[preview thumb nano].each do |variant|
          expect(media.image.variant(variant)).to be_present
        end
      end

      it "creates a media record for each of multiple images" do
        second_image_blob = ActiveStorage::Blob.create_and_upload!(
          io: StringIO.new("second image"),
          filename: "test2.jpg",
          content_type: "image/jpeg"
        )
        product.images.attach(second_image_blob)

        expect { perform_job }.to change { product.media.count }.by(2)
      end

      it "points each media to the same blob as its corresponding image" do
        second_image_blob = ActiveStorage::Blob.create_and_upload!(
          io: StringIO.new("second image"),
          filename: "test2.jpg",
          content_type: "image/jpeg"
        )
        product.images.attach(second_image_blob)

        perform_job

        image_blob_ids = product.images.map(&:blob_id).sort
        media_blob_ids = product.media.map { |m| m.image.blob_id }.sort

        expect(media_blob_ids).to eq(image_blob_ids)
      end
    end

    context "with a purchase_item having images" do
      let(:purchase_item) { create(:purchase_item) }
      let(:image_blob) do
        ActiveStorage::Blob.create_and_upload!(
          io: StringIO.new("test image content"),
          filename: "test.jpg",
          content_type: "image/jpeg"
        )
      end

      before do
        purchase_item.images.attach(image_blob)
      end

      it "creates a media record with the image attached" do
        expect { perform_job }.to change { purchase_item.media.count }.by(1)
      end

      it "points the media image to the same blob as the original image" do
        perform_job

        media = purchase_item.media.first
        expect(media.image.blob_id).to eq(purchase_item.images.first.blob_id)
      end
    end

    context "with a warehouse having images" do
      let(:warehouse) { create(:warehouse) }
      let(:image_blob) do
        ActiveStorage::Blob.create_and_upload!(
          io: StringIO.new("test image content"),
          filename: "test.jpg",
          content_type: "image/jpeg"
        )
      end

      before do
        warehouse.images.attach(image_blob)
      end

      it "creates a media record with the image attached" do
        expect { perform_job }.to change { warehouse.media.count }.by(1)
      end

      it "points the media image to the same blob as the original image" do
        perform_job

        media = warehouse.media.first
        expect(media.image.blob_id).to eq(warehouse.images.first.blob_id)
      end
    end

    context "with a record having no images" do
      let!(:product) { create(:product) }

      it "does not create a media record" do
        expect { perform_job }.not_to change { product.media.count }
      end
    end

    context "when processing multiple records" do
      let!(:products) { create_list(:product, 3) }

      before do
        products.each do |product|
          product.images.attach(
            ActiveStorage::Blob.create_and_upload!(
              io: StringIO.new("test image content"),
              filename: "test_#{product.id}.jpg",
              content_type: "image/jpeg"
            )
          )
        end
      end

      it "processes all records with images" do
        perform_job

        products.each do |product|
          expect(product.media.count).to eq(1)
        end
      end
    end

    context "when all images are already migrated" do
      let(:product) { create(:product) }
      let(:first_image_blob) do
        ActiveStorage::Blob.create_and_upload!(
          io: StringIO.new("test image content"),
          filename: "test1.jpg",
          content_type: "image/jpeg"
        )
      end
      let(:second_image_blob) do
        ActiveStorage::Blob.create_and_upload!(
          io: StringIO.new("second image"),
          filename: "test2.jpg",
          content_type: "image/jpeg"
        )
      end

      before do
        product.images.attach(first_image_blob, second_image_blob)
        # Manually create media for both images (simulating previous migration)
        media1 = create(:media, mediaable: product)
        media1.image.attach(first_image_blob)
        media2 = create(:media, mediaable: product)
        media2.image.attach(second_image_blob)
        product.reload
      end

      it "does not create duplicate media records" do
        expect { perform_job }.not_to change { product.reload.media.count }
      end

      it "is idempotent - running multiple times has no effect" do
        perform_job
        expect { perform_job }.not_to change { product.reload.media.count }
      end
    end

    context "when only some images are migrated (partial migration)" do
      let(:product) { create(:product) }
      let(:first_image_blob) do
        ActiveStorage::Blob.create_and_upload!(
          io: StringIO.new("test image content"),
          filename: "test1.jpg",
          content_type: "image/jpeg"
        )
      end
      let(:second_image_blob) do
        ActiveStorage::Blob.create_and_upload!(
          io: StringIO.new("second image"),
          filename: "test2.jpg",
          content_type: "image/jpeg"
        )
      end

      before do
        product.images.attach(first_image_blob, second_image_blob)
        # Only migrate the first image
        media1 = create(:media, mediaable: product)
        media1.image.attach(first_image_blob)
        product.reload
      end

      it "creates media only for the non-migrated image" do
        expect { perform_job }.to change { product.reload.media.count }.by(1)
      end

      it "points the new media to the correct blob", :aggregate_failures do # rubocop:todo RSpec/MultipleExpectations
        perform_job

        # Should have 2 media total now
        expect(product.media.count).to eq(2)

        # Find the media for blob2 (the newly migrated one)
        new_media = product.media.find { |m| m.image.blob_id == second_image_blob.id }
        expect(new_media).to be_present
        expect(new_media.image.blob_id).to eq(second_image_blob.id)
      end

      it "does not create duplicate media for already-migrated images" do
        perform_job

        # first_image_blob should still only have one media record
        blob1_media_count = product.media.count { |m| m.image.blob_id == first_image_blob.id }
        expect(blob1_media_count).to eq(1)
      end
    end

    context "when variant generation fails" do
      let(:product) { create(:product) }
      let(:image_blob) do
        ActiveStorage::Blob.create_and_upload!(
          io: StringIO.new("test image content"),
          filename: "test.jpg",
          content_type: "image/jpeg"
        )
      end

      before do
        product.images.attach(image_blob)
      end

      it "continues migration despite variant failures", :aggregate_failures do # rubocop:todo RSpec/MultipleExpectations
        # rubocop:disable RSpec/AnyInstance -- testing error handling for variant generation
        allow_any_instance_of(ActiveStorage::Variant).to receive(:processed).and_raise(StandardError, "variant error")
        # rubocop:enable RSpec/AnyInstance

        expect { perform_job }.to change { product.media.count }.by(1)
        expect(product.media.first.image).to be_attached
      end
    end
  end

  it "is configured to use the default queue" do
    expect(described_class.new.queue_name).to eq("default")
  end

  def perform_job
    described_class.new.perform
  end
end
