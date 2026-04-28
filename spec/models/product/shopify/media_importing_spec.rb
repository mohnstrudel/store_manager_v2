# frozen_string_literal: true

require "rails_helper"

RSpec.describe Product::Shopify::MediaImporting do
  let(:product) { create(:product) }
  let(:downloaded_file) { instance_double("DownloadedFiles") }
  let(:upsert) { instance_double(Product::Shopify::Media::Upsert) }

  let(:parsed_media) do
    [
      {
        key: "gid://shopify/MediaImage/1",
        id: "gid://shopify/MediaImage/1",
        url: "https://example.com/one.jpg",
        alt: "One",
        position: 0,
        store_info: {
          ext_created_at: "2024-01-01T00:00:00Z",
          ext_updated_at: "2024-01-02T00:00:00Z"
        }
      },
      {
        key: "gid://shopify/MediaImage/2",
        id: "gid://shopify/MediaImage/2",
        url: "https://example.com/two.jpg",
        alt: "Two",
        position: 1,
        store_info: {
          ext_created_at: "2024-01-01T00:00:00Z",
          ext_updated_at: "2024-01-02T00:00:00Z"
        }
      }
    ]
  end

  before do
    allow(Product::Shopify::Media::Downloader).to receive(:call).and_return(downloaded_file)
    allow(Product::Shopify::Media::Upsert).to receive(:new).with(product:).and_return(upsert)
    allow(upsert).to receive(:call)
    allow(downloaded_file).to receive_messages(
      downloaded_checksums: ["checksum-one"],
      failed_store_ids: ["gid://shopify/MediaImage/2"],
      downloads_by_key: {"gid://shopify/MediaImage/1" => instance_double("Download", checksum: "checksum-one")},
      close_downloads!: true
    )
  end

  describe "#import_shopify_media" do
    it "clears local media when parsed_media is blank" do
      create_list(:media, 2, mediaable: product)

      expect {
        product.import_shopify_media(parsed_media: [])
      }.to change { product.media.count }.from(2).to(0)
    end

    it "downloads, removes obsolete media, upserts downloads, and closes files" do
      kept_media = create(:media, mediaable: product, alt: "Keep", position: 0)
      obsolete_media = create(:media, mediaable: product, alt: "Obsolete", position: 1)
      failed_media = create(:media, mediaable: product, alt: "Failed", position: 2)

      kept_media.image.purge
      kept_media.image.attach(io: StringIO.new("keep image"), filename: "keep.jpg", content_type: "image/jpeg")

      obsolete_media.image.purge
      obsolete_media.image.attach(io: StringIO.new("obsolete image"), filename: "obsolete.jpg", content_type: "image/jpeg")

      failed_media.image.purge
      failed_media.image.attach(io: StringIO.new("failed image"), filename: "failed.jpg", content_type: "image/jpeg")
      create(:store_info, :shopify, storable: failed_media, store_id: "gid://shopify/MediaImage/2")

      allow(downloaded_file).to receive_messages(
        downloaded_checksums: [kept_media.image.blob.checksum],
        failed_store_ids: ["gid://shopify/MediaImage/2"],
        downloads_by_key: {
          "gid://shopify/MediaImage/1" => instance_double("Download", checksum: kept_media.image.blob.checksum)
        }
      )

      expect(Product::Shopify::Media::Downloader).to receive(:call).with(media_items: parsed_media)
      expect(Product::Shopify::Media::Upsert).to receive(:new).with(product:).and_return(upsert)
      expect(upsert).to receive(:call).with(
        media_items: parsed_media,
        downloads_by_key: downloaded_file.downloads_by_key
      )

      expect {
        product.import_shopify_media(parsed_media:)
      }.to change { product.media.count }.by(-1)

      expect(kept_media.reload).to be_persisted
      expect(failed_media.reload).to be_persisted
      expect { obsolete_media.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect(downloaded_file).to have_received(:close_downloads!)
    end
  end
end
