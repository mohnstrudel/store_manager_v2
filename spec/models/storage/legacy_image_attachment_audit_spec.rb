# frozen_string_literal: true

require "rails_helper"

RSpec.describe Storage::LegacyImageAttachmentAudit do
  def uploaded_blob
    ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new("legacy image data"),
      filename: "legacy.jpg",
      content_type: "image/jpeg"
    )
  end

  def legacy_attachment(record, blob: uploaded_blob)
    ActiveStorage::Attachment.create!(name: "images", record:, blob:)
  end

  describe ".call" do
    it "returns an empty result when there are no legacy attachments" do
      result = described_class.call

      expect(result.total).to eq(0)
      expect(result.blocked?).to be false
    end

    it "classifies a row as retained when its blob is also attached as Media#image on the same owner" do
      product = create(:product)
      media = create(:media, :for_product, mediaable: product)
      attachment = legacy_attachment(product, blob: media.image.blob)

      result = described_class.call

      expect(result.retained_ids).to eq([attachment.id])
      expect(result.releasing_bytes).to eq(0)
    end

    it "classifies a row as retained when its blob is attached as Media#image on a different record" do
      owner = create(:product)
      create(:media, :for_product, mediaable: owner)
      other_product = create(:product)
      other_media = create(:media, :for_product, mediaable: other_product)
      shared_blob = uploaded_blob
      other_media.image.attach(shared_blob)
      attachment = legacy_attachment(owner, blob: shared_blob)

      result = described_class.call

      expect(result.retained_ids).to eq([attachment.id])
    end

    it "classifies as releasing when the owner has different Media and is Shopify-linked" do
      product = create(:product)
      create(:media, :for_product, mediaable: product)
      attachment = legacy_attachment(product)

      result = described_class.call

      expect(result.releasing_ids).to eq([attachment.id])
      expect(result.releasing_unrecoverable_ids).to be_empty
      expect(result.releasing_bytes).to eq(attachment.blob.byte_size)
    end

    it "classifies as releasing_unrecoverable when the owner has no Shopify link" do
      product = create(:product)
      product.shopify_info.destroy
      create(:media, :for_product, mediaable: product)
      attachment = legacy_attachment(product)

      result = described_class.call

      expect(result.releasing_unrecoverable_ids).to eq([attachment.id])
      expect(result.releasing_ids).to be_empty
    end

    it "classifies a Warehouse legacy row the same way as Product" do
      warehouse = create(:warehouse)
      create(:media, :for_warehouse, mediaable: warehouse)
      attachment = legacy_attachment(warehouse)

      result = described_class.call

      expect(result.releasing_unrecoverable_ids).to eq([attachment.id])
    end

    it "classifies as blocked when the owner has no image-bearing Media" do
      product = create(:product)
      attachment = legacy_attachment(product)

      result = described_class.call

      expect(result.blocked_ids).to eq([attachment.id])
      expect(result.blocked_owners).to eq([["Product", product.id]])
      expect(result.blocked?).to be true
    end

    it "classifies as blocked when the owner's only Media has no attached image" do
      product = create(:product)
      product.media.create!(position: 0)
      attachment = legacy_attachment(product)

      result = described_class.call

      expect(result.blocked_ids).to eq([attachment.id])
    end

    it "classifies as orphaned_owner when the owning record no longer exists" do
      product = create(:product)
      attachment = legacy_attachment(product)
      product.destroy

      result = described_class.call

      expect(result.orphaned_owner_ids).to eq([attachment.id])
      expect(result.blocked_ids).to be_empty
    end

    it "classifies each legacy row on the same owner independently" do
      product = create(:product)
      media = create(:media, :for_product, mediaable: product)

      retained_attachment = legacy_attachment(product, blob: media.image.blob)
      releasing_attachment = legacy_attachment(product)

      result = described_class.call

      expect(result.retained_ids).to contain_exactly(retained_attachment.id)
      expect(result.releasing_ids).to contain_exactly(releasing_attachment.id)
      expect(result.total).to eq(2)
    end
  end

  describe "Result#deletable_ids" do
    it "includes retained, releasing, and orphaned_owner ids, excluding unrecoverable by default" do
      result = described_class::Result.new(
        retained_ids: [1], releasing_ids: [2], releasing_unrecoverable_ids: [3],
        orphaned_owner_ids: [4], blocked_ids: [], blocked_owners: [],
        releasing_bytes: 0, total: 4
      )

      expect(result.deletable_ids).to contain_exactly(1, 2, 4)
      expect(result.deletable_ids(allow_unrecoverable: true)).to contain_exactly(1, 2, 3, 4)
    end
  end

  describe "Result#released_ids" do
    it "includes releasing and orphaned_owner ids, excluding retained and unrecoverable by default" do
      result = described_class::Result.new(
        retained_ids: [1], releasing_ids: [2], releasing_unrecoverable_ids: [3],
        orphaned_owner_ids: [4], blocked_ids: [], blocked_owners: [],
        releasing_bytes: 0, total: 4
      )

      expect(result.released_ids).to contain_exactly(2, 4)
      expect(result.released_ids(allow_unrecoverable: true)).to contain_exactly(2, 3, 4)
    end
  end
end
