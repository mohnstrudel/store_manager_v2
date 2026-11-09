# frozen_string_literal: true

require "rails_helper"
require "support/contracts/media_contract"

RSpec.describe Shopify::ImportMediaJob do
  include Helpers::ShopifyMediaScenarios

  subject(:job) { described_class.new }

  let(:product) { create(:product) }
  let(:shopify_image_number) { 123456789 }
  let(:shopify_image_id) { media_gid(shopify_image_number) }
  let(:img_url) { "https://example.com/image.jpg?v=1" }
  let(:alt_text) { "Beautiful product photo" }
  let(:position) { 3 }

  let(:parsed_media_item) do
    {
      key: shopify_image_id,
      id: shopify_image_id,
      url: img_url,
      alt: alt_text,
      position: position
    }
  end

  let(:parsed_media) { [parsed_media_item] }

  let(:test_image_content) { "fake jpeg binary content" }
  let(:test_checksum) { Digest::MD5.base64digest(test_image_content) }
  let(:test_filename) { "product-image.jpg" }

  before do
    temp_file = Tempfile.new(["test_", ".jpg"], Rails.root.join("tmp"))
    temp_file.write(test_image_content)
    temp_file.rewind
    filename_value = test_filename
    temp_file.define_singleton_method(:original_filename) do
      filename_value
    end
    allow(Down).to receive(:download).with(img_url, anything).and_return(temp_file)
  end

  describe "queue" do
    it { expect(described_class.new.queue_name).to eq "media" }
  end

  describe "media contract" do
    it_behaves_like "valid media contract"
  end

  describe "#perform" do
    it "imports Shopify media through the domain without forcing" do
      allow(product).to receive(:import_shopify_media)

      job.perform(product, parsed_media)

      expect(product).to have_received(:import_shopify_media).with(parsed_media:, force: false)
    end

    it "passes force through to the domain" do
      allow(product).to receive(:import_shopify_media)

      job.perform(product, parsed_media, force: true)

      expect(product).to have_received(:import_shopify_media).with(parsed_media:, force: true)
    end

    context "when parsed_media is empty" do
      it "removes all local media" do
        media = create_list(:media, 2, mediaable: product)
        create(:store_info, :shopify, storable: media.first)

        expect { job.perform(product, []) }
          .to change { product.media.count }.from(2).to(0)
      end

      it "removes associated store_infos" do
        media = create_list(:media, 2, mediaable: product)
        create(:store_info, :shopify, storable: media.first)

        expect { job.perform(product, []) }
          .to change { StoreInfo.where(storable_type: "Media").count }.by(-1)
      end
    end

    context "when creating a new image" do
      it "creates media + attachment + store_info" do
        freeze_time do
          expect { job.perform(product, parsed_media) }
            .to change { product.media.count }.by(1)
            .and change { StoreInfo.where(storable_type: "Media").count }.by(1)

          media = product.media.last
          expect(media).to have_attributes(alt: alt_text, position: position)
          expect(media.image).to be_attached
          expect(media.image.blob.checksum).to eq test_checksum

          si = media.store_infos.shopify.first
          expect(si).to have_attributes(
            store_id: shopify_image_id,
            source_url: img_url,
            alt_text: alt_text,
            checksum: test_checksum
          )
          expect(si.pull_time).to be_within(1.second).of(Time.current)
        end
      end
    end

    context "when the media URL is unchanged" do
      let!(:media) do
        pulled_media(test_image_content, number: shopify_image_number, source_url: img_url, alt: "old", position: 99)
      end

      it "updates alt, position, and pull_time without downloading" do
        expect { job.perform(product, parsed_media) }
          .to change { media.reload.alt }.to(alt_text)
          .and change { media.reload.position }.to(position)
          .and change { media.shopify_info.reload.pull_time }

        expect(Down).not_to have_received(:download)
      end
    end

    context "when the media URL changed and the bytes differ" do
      let!(:media) do
        pulled_media("old content", number: shopify_image_number, source_url: "https://example.com/image.jpg?v=0")
      end

      it "replaces the attachment on the same media row" do
        expect { job.perform(product, parsed_media) }.not_to change(Media, :count)

        expect(media.reload.image.blob.checksum).to eq test_checksum
        expect(media.shopify_info).to have_attributes(source_url: img_url, checksum: test_checksum)
      end
    end

    context "when partial download fails" do
      let(:failed_url) { "https://404.example.com/image.jpg?v=2" }
      let(:parsed_media) do
        [
          parsed_media_item,
          parsed_media_item.merge(key: media_gid(999), id: media_gid(999), url: failed_url)
        ]
      end

      before do
        allow(Down).to receive(:download).with(failed_url, anything)
          .and_raise(Down::Error.new("404 Not Found"))
      end

      it "processes successful images and preserves failed remote media" do
        failed_remote_media = pulled_media("remote", number: 999, source_url: "https://404.example.com/image.jpg?v=1")

        job.perform(product, parsed_media)

        expect(Media.where(id: failed_remote_media.id)).to exist
        expect(failed_remote_media.reload.shopify_info.source_url).to eq "https://404.example.com/image.jpg?v=1"
        expect(product.media.count).to eq 2

        new_media = product.media.ordered.last
        expect(new_media.alt).to eq alt_text
        expect(new_media.image).to be_attached
      end
    end
  end
end
