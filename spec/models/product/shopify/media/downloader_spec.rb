# frozen_string_literal: true

require "rails_helper"

RSpec.describe Product::Shopify::Media::Downloader do
  let(:success_url_1) { "https://example.com/one.jpg" }
  let(:success_url_2) { "https://example.com/two.jpg" }
  let(:failed_url) { "https://example.com/fail.jpg" }
  let(:store_id_1) { "gid://shopify/ProductImage/1" }
  let(:store_id_2) { "gid://shopify/ProductImage/2" }
  let(:failed_store_id) { "gid://shopify/ProductImage/3" }

  let(:media_items) do
    [
      {key: "first", id: store_id_1, url: success_url_1},
      {key: "failed", id: failed_store_id, url: failed_url},
      {key: "second", id: store_id_2, url: success_url_2}
    ]
  end

  let(:successful_media_items) { [media_items.first, media_items.last] }

  let(:file_1) { Tempfile.new(["one", ".jpg"]) }
  let(:file_2) { Tempfile.new(["two", ".jpg"]) }

  before do
    file_1.write("image one")
    file_1.rewind
    file_1.define_singleton_method(:original_filename) { "one.jpg" }

    file_2.write("image two")
    file_2.rewind
    file_2.define_singleton_method(:original_filename) { "two.jpg" }
  end

  after do
    file_1.close!
    file_2.close!
  end

  describe ".call" do
    it "downloads successful items and keeps processing after a failure" do
      allow(Down).to receive(:download).with(success_url_1, anything).and_return(file_1)
      allow(Down).to receive(:download).with(failed_url, anything).and_raise(Down::Error.new("404 Not Found"))
      allow(Down).to receive(:download).with(success_url_2, anything).and_return(file_2)

      result = described_class.call(media_items:)

      expect(result.downloads_by_key.keys).to contain_exactly("first", "second")
      expect(result.failed_store_ids).to contain_exactly(failed_store_id)
    end

    it "tracks successful downloads and exposes their checksums" do
      allow(Down).to receive(:download).with(success_url_1, anything).and_return(file_1)
      allow(Down).to receive(:download).with(success_url_2, anything).and_return(file_2)

      result = described_class.call(media_items: successful_media_items)

      expect(result.downloads_by_key.keys).to contain_exactly("first", "second")
      expect(result.downloaded_checksums).to all(be_a(String))
    end
  end
end
