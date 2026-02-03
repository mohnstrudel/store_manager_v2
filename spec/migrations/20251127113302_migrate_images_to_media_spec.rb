# frozen_string_literal: true

require "rails_helper"

RSpec.describe "MigrateImagesToMedia" do
  # This spec tests the migration that migrates images from has_many_attached :images
  # to the new Media polymorphic association
  #
  # The migration should:
  # 1. Create Media records for each image attachment
  # 2. Create NEW ActiveStorage attachments for Media records (not update existing)
  # 3. Preserve image order (position) based on attachment creation order
  # 4. Not duplicate any blob data

  let(:image_data) { StringIO.new("test image data") }

  def create_test_image
    {io: image_data, filename: "test.jpg", content_type: "image/jpeg"}
  end

  def reset_migration
    # Clean up any existing data
    Media.delete_all
    ActiveStorage::Attachment.delete_all
    ActiveStorage::Blob.delete_all
  end

  before { reset_migration }

  after { reset_migration }

  context "with Product images" do
    let!(:product) { create(:product) }
    let!(:blob1) { create(:blob) }
    let!(:blob2) { create(:blob) }
    let!(:blob3) { create(:blob) }
    let!(:attachment1) do
      create(:attachment, name: "images", record: product, blob: blob1)
    end
    let!(:attachment2) do
      create(:attachment, name: "images", record: product, blob: blob2)
    end
    let!(:attachment3) do
      create(:attachment, name: "images", record: product, blob: blob3)
    end

    it "creates Media records for each image" do
      expect { run_migration }.to change(Media.where(mediaable_type: "Product"), :count).by(3)
    end

    it "sets correct mediaable_id and mediaable_type" do
      run_migration

      media_records = Media.where(mediaable_type: "Product", mediaable_id: product.id)
      expect(media_records.count).to eq(3)
    end

    it "preserves image order via position" do
      run_migration

      media_records = Media.where(mediaable: product).ordered
      expect(media_records.pluck(:position)).to eq([1, 2, 3])
    end

    it "creates new attachments for Media records" do
      run_migration

      product_media = Media.where(mediaable: product).ordered
      media_attachments = ActiveStorage::Attachment.where(record_type: "Media", name: "image")

      expect(media_attachments.count).to eq(3)
      expect(media_attachments.pluck(:record_id)).to match_array(product_media.pluck(:id))
    end

    it "keeps original attachments intact" do
      original_attachment_ids = [attachment1.id, attachment2.id, attachment3.id]

      run_migration

      # Original attachments should still exist pointing to Product
      product_attachments = ActiveStorage::Attachment.where(record_type: "Product", record_id: product.id, name: "images")
      expect(product_attachments.count).to eq(3)
      expect(product_attachments.pluck(:id)).to match_array(original_attachment_ids)
    end

    it "doubles the attachment count (originals + new Media attachments)" do
      expect { run_migration }
        .to change(ActiveStorage::Attachment, :count)
        .by(3)
    end

    it "does not duplicate blob data" do
      expect { run_migration }.not_to change(ActiveStorage::Blob, :count)
    end

    it "associates the correct blobs with media records" do
      run_migration

      product_media = Media.where(mediaable: product).ordered

      expect(product_media[0].image.blob_id).to eq(blob1.id)
      expect(product_media[1].image.blob_id).to eq(blob2.id)
      expect(product_media[2].image.blob_id).to eq(blob3.id)
    end
  end

  context "with PurchaseItem images" do
    let(:product) { create(:product) }
    let(:purchase) { create(:purchase, product:) }
    let!(:purchase_item) { create(:purchase_item, purchase:) }
    let!(:blob) { create(:blob) }
    let!(:attachment) do
      create(:attachment, name: "images", record: purchase_item, blob:)
    end

    it "creates Media records for PurchaseItem images" do
      expect { run_migration }.to change(Media.where(mediaable_type: "PurchaseItem"), :count).by(1)
    end

    it "sets correct associations" do
      run_migration

      media = Media.find_by(mediaable: purchase_item)
      expect(media).to be_present
      expect(media.image.blob_id).to eq(blob.id)
    end
  end

  context "with Warehouse images" do
    let!(:warehouse) { create(:warehouse) }
    let!(:blob1) { create(:blob) }
    let!(:blob2) { create(:blob) }
    let!(:attachment1) do
      create(:attachment, name: "images", record: warehouse, blob: blob1)
    end
    let!(:attachment2) do
      create(:attachment, name: "images", record: warehouse, blob: blob2)
    end

    it "creates Media records for Warehouse images" do
      expect { run_migration }.to change(Media.where(mediaable_type: "Warehouse"), :count).by(2)
    end

    it "sets correct positions" do
      run_migration

      media_records = Media.where(mediaable: warehouse).ordered
      expect(media_records.pluck(:position)).to eq([1, 2])
    end
  end

  context "with multiple models" do
    let!(:product) { create(:product) }
    let!(:warehouse) { create(:warehouse) }
    let!(:product_blob) { create(:blob) }
    let!(:warehouse_blob) { create(:blob) }
    let!(:product_attachment) do
      create(:attachment, name: "images", record: product, blob: product_blob)
    end
    let!(:warehouse_attachment) do
      create(:attachment, name: "images", record: warehouse, blob: warehouse_blob)
    end

    it "creates Media records for all model types" do
      expect { run_migration }.to change(Media, :count).by(2)
    end

    it "creates media with correct mediaable_types" do
      run_migration

      expect(Media.where(mediaable_type: "Product").count).to eq(1)
      expect(Media.where(mediaable_type: "Warehouse").count).to eq(1)
    end
  end

  context "with records that have no images" do
    let!(:product) { create(:product) }

    it "does not create Media records" do
      expect { run_migration }.not_to change(Media, :count)
    end
  end

  context "when migration is run multiple times" do
    let!(:product) { create(:product) }
    let!(:blob) { create(:blob) }
    let!(:attachment) do
      create(:attachment, name: "images", record: product, blob:)
    end

    it "uses ON CONFLICT DO NOTHING to avoid duplicates" do
      run_migration
      initial_count = Media.count

      expect { run_migration }.not_to change(Media, :count).from(initial_count)
    end
  end

  context "down migration" do
    let!(:product) { create(:product) }
    let!(:blob) { create(:blob) }
    let!(:attachment) do
      create(:attachment, name: "images", record: product, blob:)
    end

    before { run_migration }

    it "deletes Media records" do
      expect { run_down_migration }.to change(Media.where(mediaable_type: "Product"), :count).by(-1)
    end
  end

  private

  def run_migration
    ActiveRecord::Base.connection.execute(<<~SQL.squish)
      WITH numbered_attachments AS (
        SELECT
          a.id AS old_attachment_id,
          a.record_type,
          a.record_id,
          a.blob_id,
          ROW_NUMBER() OVER (PARTITION BY a.record_type, a.record_id ORDER BY a.id) AS position
        FROM active_storage_attachments a
        WHERE a.name = 'images'
          AND a.record_type IN ('Product', 'PurchaseItem', 'Warehouse')
          AND NOT EXISTS (
            SELECT 1 FROM media m
            WHERE m.mediaable_type = a.record_type
              AND m.mediaable_id = a.record_id
          )
      ),
      inserted_media AS (
        INSERT INTO media (mediaable_type, mediaable_id, position, alt, created_at, updated_at)
        SELECT
          record_type,
          record_id,
          position,
          '',
          NOW(),
          NOW()
        FROM numbered_attachments
        ON CONFLICT DO NOTHING
        RETURNING id, mediaable_type, mediaable_id, position
      ),
      numbered_media AS (
        SELECT
          inserted_media.id AS media_id,
          mediaable_type,
          mediaable_id,
          inserted_media.position,
          ROW_NUMBER() OVER (PARTITION BY mediaable_type, mediaable_id ORDER BY id) AS rn
        FROM inserted_media
      ),
      numbered_attachments_with_rn AS (
        SELECT
          old_attachment_id,
          record_type,
          record_id,
          blob_id,
          position,
          ROW_NUMBER() OVER (PARTITION BY record_type, record_id ORDER BY old_attachment_id) AS rn
        FROM numbered_attachments
      ),
      new_attachment_ids AS (
        SELECT
          (SELECT COALESCE(MAX(id), 0) FROM active_storage_attachments) + ROW_NUMBER() OVER (ORDER BY old_attachment_id) AS new_attachment_id,
          old_attachment_id,
          blob_id
        FROM numbered_attachments_with_rn
      ),
      inserted_attachments AS (
        INSERT INTO active_storage_attachments (id, record_type, record_id, name, blob_id, created_at)
        SELECT
          new_attachment_id,
          'Media',
          numbered_media.media_id,
          'image',
          numbered_attachments_with_rn.blob_id,
          NOW()
        FROM numbered_attachments_with_rn
        JOIN numbered_media
          ON numbered_media.mediaable_type = numbered_attachments_with_rn.record_type
          AND numbered_media.mediaable_id = numbered_attachments_with_rn.record_id
          AND numbered_media.rn = numbered_attachments_with_rn.rn
        JOIN new_attachment_ids
          ON new_attachment_ids.old_attachment_id = numbered_attachments_with_rn.old_attachment_id
        ON CONFLICT (id) DO NOTHING
        RETURNING id
    )
    SELECT 1
    SQL
  end

  def run_down_migration
    ActiveRecord::Base.connection.execute(
      "DELETE FROM media WHERE mediaable_type IN ('Product', 'PurchaseItem', 'Warehouse')"
    )
  end
end
