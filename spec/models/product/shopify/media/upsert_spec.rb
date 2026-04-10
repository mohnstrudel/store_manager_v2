# frozen_string_literal: true

require "rails_helper"

RSpec.describe Product::Shopify::Media::Upsert do
  let(:product) { create(:product) }
  let(:existing_media) { create(:media, mediaable: product, alt: "Old alt", position: 1) }
  let(:new_file) do
    Tempfile.new(["new-media", ".jpg"]).tap do |file|
      file.write("new media content")
      file.rewind
    end
  end
  let(:existing_file) do
    Tempfile.new(["existing-media", ".jpg"]).tap do |file|
      file.write("existing media content")
      file.rewind
    end
  end
  let(:existing_download) do
    Product::Shopify::Media::Downloader::DownloadedImage.new(
      file: existing_file,
      filename: "existing.jpg",
      checksum: existing_media.image.blob.checksum
    )
  end
  let(:new_download) do
    Product::Shopify::Media::Downloader::DownloadedImage.new(
      file: new_file,
      filename: "new.jpg",
      checksum: "new-checksum"
    )
  end
  let(:downloads_by_key) do
    {
      "existing" => existing_download,
      "new" => new_download
    }
  end
  let(:media_items) do
    [
      {
        key: "existing",
        id: "gid://shopify/MediaImage/1",
        alt: "Updated alt",
        position: 3,
        store_info: {
          ext_created_at: "2024-01-01T00:00:00Z",
          ext_updated_at: "2024-01-02T00:00:00Z"
        }
      },
      {
        key: "new",
        id: "gid://shopify/MediaImage/2",
        alt: "Brand new",
        position: 4,
        store_info: {
          ext_created_at: "2024-01-03T00:00:00Z",
          ext_updated_at: "2024-01-04T00:00:00Z"
        }
      },
      {
        key: "missing",
        id: "gid://shopify/MediaImage/3",
        alt: "Skipped",
        position: 5
      }
    ]
  end

  after do
    existing_file.close! if existing_file
    new_file.close! if new_file
  end

  describe "#call" do
    it "reuses matching media by checksum and creates missing media" do
      create(:store_info, :shopify,
        storable: existing_media,
        store_id: "gid://shopify/MediaImage/1",
        checksum: existing_media.image.blob.checksum,
        alt_text: "Old alt")

      expect {
        described_class.new(product:).call(media_items:, downloads_by_key:)
      }.to change { product.media.count }.by(1)

      existing_media.reload
      expect(existing_media.alt).to eq("Updated alt")
      expect(existing_media.position).to eq(3)
      expect(existing_media.shopify_info.store_id).to eq("gid://shopify/MediaImage/1")
      expect(existing_media.shopify_info.checksum).to eq(existing_media.image.blob.checksum)

      new_media = product.media.find_by(alt: "Brand new")
      expect(new_media).to be_present
      expect(new_media.image).to be_attached
      expect(new_media.shopify_info.store_id).to eq("gid://shopify/MediaImage/2")
      expect(new_media.shopify_info.checksum).to eq("new-checksum")
    end

    it "skips media without a downloaded file" do
      expect {
        described_class.new(product:).call(
          media_items: media_items,
          downloads_by_key: {}
        )
      }.not_to change(product.media, :count)
    end

    it "reattaches a matching checksum when the existing blob is missing from storage" do
      create(:store_info, :shopify,
        storable: existing_media,
        store_id: "gid://shopify/MediaImage/1",
        checksum: existing_media.image.blob.checksum)

      service = instance_double(
        ActiveStorage::Service,
        exist?: false,
        delete: true,
        delete_prefixed: true
      )
      allow(existing_media.image.blob).to receive(:service).and_return(service)
      upsert = described_class.new(product:)
      allow(upsert).to receive(:existing_media_by_checksum).and_return(
        existing_media.image.blob.checksum => existing_media
      )

      expect {
        upsert.call(
          media_items: [media_items.first],
          downloads_by_key: {"existing" => existing_download}
        )
      }.not_to change(product.media, :count)

      existing_media.reload
      expect(existing_media.image).to be_attached
      expect(existing_media.image.filename.to_s).to eq("existing.jpg")
      expect(existing_media.shopify_info.store_id).to eq("gid://shopify/MediaImage/1")
    end
  end
end
