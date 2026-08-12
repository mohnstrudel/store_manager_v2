# frozen_string_literal: true

require "rails_helper"

RSpec.describe Media::LegacyAttachments::Backfill do
  def uploaded_blob(contents = "legacy image data")
    ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new(contents),
      filename: "legacy.jpg",
      content_type: "image/jpeg"
    )
  end

  def legacy_attachment(record, blob: uploaded_blob)
    ActiveStorage::Attachment.create!(name: Media::LegacyAttachments::NAME, record:, blob:)
  end

  describe ".apply!" do
    it "creates ordered Media for a product with legacy images and no Media", :aggregate_failures do
      product = create(:product)
      blob_a = uploaded_blob("first")
      blob_b = uploaded_blob("second")
      legacy_attachment(product, blob: blob_a)
      legacy_attachment(product, blob: blob_b)

      result = described_class.apply!

      expect(result.created_count).to eq(2)
      expect(result.owners_backfilled).to eq(1)
      expect(product.media.ordered.map { |media| media.image.blob }).to eq([blob_a, blob_b])
      expect(product.media.ordered.map(&:position)).to eq([0, 1])
    end

    it "completes a partial blob-level backfill without duplicating covered images" do
      product = create(:product)
      blob_a = uploaded_blob("first")
      blob_b = uploaded_blob("second")
      legacy_attachment(product, blob: blob_a)
      legacy_attachment(product, blob: blob_b)
      product.media.create!(image: blob_a, position: 0)

      result = described_class.apply!

      expect(result.created_count).to eq(1)
      expect(product.media.ordered.map { |media| media.image.blob_id }).to eq([blob_a.id, blob_b.id])
    end

    it "skips owners whose current Media has no legacy blob overlap" do
      product = create(:product)
      existing_media = create(:media, :for_product, mediaable: product)
      legacy_attachment(product)

      result = described_class.apply!

      expect(result.created_count).to eq(0)
      expect(product.media.reload).to eq([existing_media])
    end

    it "treats a Media row with no attached image as still needing backfill" do
      product = create(:product)
      product.media.create!(position: 0)
      legacy_attachment(product)

      result = described_class.apply!

      expect(result.created_count).to eq(1)
      expect(product.media.count).to eq(2)
    end

    it "backfills PurchaseItems and Warehouses as supported legacy owners" do
      purchase_item = create(:purchase_item)
      warehouse = create(:warehouse)
      legacy_attachment(purchase_item)
      legacy_attachment(warehouse)

      result = described_class.apply!

      expect(result.created_count).to eq(2)
      expect(purchase_item.media.count).to eq(1)
      expect(warehouse.media.count).to eq(1)
    end

    it "rolls back a whole owner when one Media save fails and retries cleanly" do
      product = create(:product)
      legacy_attachment(product, blob: uploaded_blob("first"))
      legacy_attachment(product, blob: uploaded_blob("second"))
      save_attempt = 0

      # rubocop:disable RSpec/AnyInstance -- exercise the transaction across owner-built Media records
      allow_any_instance_of(Media).to receive(:save!).and_wrap_original do |method, *arguments|
        save_attempt += 1
        raise "interrupted owner backfill" if save_attempt == 2

        method.call(*arguments)
      end

      expect { described_class.apply! }.to raise_error("interrupted owner backfill")
      expect(product.media.count).to eq(0)

      allow_any_instance_of(Media).to receive(:save!).and_call_original
      result = described_class.apply!
      # rubocop:enable RSpec/AnyInstance

      expect(result.created_count).to eq(2)
      expect(product.media.count).to eq(2)
    end

    it "is idempotent" do
      product = create(:product)
      legacy_attachment(product)

      described_class.apply!
      result = described_class.apply!

      expect(result.created_count).to eq(0)
      expect(product.media.count).to eq(1)
    end

    it "does not touch owners with no legacy attachment" do
      create(:product)

      result = described_class.apply!

      expect(result.created_count).to eq(0)
      expect(result.owners_backfilled).to eq(0)
    end
  end
end
