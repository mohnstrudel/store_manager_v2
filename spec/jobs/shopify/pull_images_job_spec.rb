# frozen_string_literal: true

require "rails_helper"

describe Shopify::PullImagesJob do
  include ActiveJob::TestHelper

  let(:job) { described_class.new }
  let(:product) { create(:product) }
  let(:img_url) { "http://example.com/image.jpg" }
  let(:updated_at) { 1.hour.ago.iso8601 }
  let(:parsed_media) do
    [
      {
        id: "gid://shopify/ProductImage/123",
        url: img_url,
        alt: "Test Alt",
        position: 1,
        updated_at:
      }
    ]
  end
  let(:test_image_data) { "test image content" }
  let(:test_file_path) { Rails.root.join("tmp/test_image_#{SecureRandom.hex(8)}.jpg") }
  let(:checksum) { Digest::MD5.file(test_file_path.to_s).base64digest }

  before do
    File.write(test_file_path, test_image_data)
  end

  after do
    File.delete(test_file_path) if File.exist?(test_file_path)
  end

  describe "#perform" do
    let(:uri_double) { instance_double(URI::HTTP, path: "/image.jpg") }
    let(:test_io) { File.open(test_file_path) }

    after do
      test_io.close if test_io && !test_io.closed?
    end

    context "when product and parsed_media are present" do
      before do
        allow(URI).to receive(:parse).with(img_url).and_return(uri_double)
        allow(uri_double).to receive(:open).and_return(test_io)
      end

      # rubocop:disable RSpec/MultipleExpectations
      it "creates new media with store info when store info does not exist" do
        expect do
          job.perform(product, parsed_media)
        end.to change(product.media, :count).by(1)
          .and change(StoreInfo.where(storable_type: "Media"), :count).by(1)

        media = product.media.last
        expect(media.alt).to eq "Test Alt"
        expect(media.position).to eq 1

        store_info = media.store_infos.first
        expect(store_info.store_id).to eq "gid://shopify/ProductImage/123"
        expect(store_info.store_name).to eq "shopify"
        expect(store_info.pull_time).to be_within(2.seconds).of(1.hour.ago)
      end
      # rubocop:enable RSpec/MultipleExpectations

      # rubocop:disable RSpec/MultipleExpectations
      it "reuses existing media when checksum matches" do
        existing_media = create(:media, mediaable: product)
        existing_media.image.blob.checksum

        parsed_media_with_same_checksum = [
          {
            id: "gid://shopify/ProductImage/456",
            url: img_url,
            alt: "Different Alt",
            position: 2,
            updated_at:
          }
        ]

        new_test_file = Rails.root.join("tmp/test_image_#{SecureRandom.hex(8)}.jpg")
        File.write(new_test_file, existing_media.image.download)
        new_test_io = File.open(new_test_file)

        allow(uri_double).to receive(:open).and_return(new_test_io)

        # rubocop:disable RSpec/ChangeByZero
        expect do
          job.perform(product, parsed_media_with_same_checksum)
        end.to change(product.media, :count).by(0)
          .and change(StoreInfo.where(storable_type: "Media"), :count).by(1)
        # rubocop:enable RSpec/ChangeByZero

        existing_media.reload
        expect(existing_media.alt).to eq "Different Alt"
        expect(existing_media.position).to eq 2

        new_store_info = existing_media.store_infos.find_by(store_id: "gid://shopify/ProductImage/456")
        expect(new_store_info).to be_present

        new_test_io.close if new_test_io && !new_test_io.closed?
        File.delete(new_test_file) if File.exist?(new_test_file)
      end
      # rubocop:enable RSpec/MultipleExpectations
    end

    context "when store info already exists" do
      let!(:existing_media) { create(:media, mediaable: product, alt: "Old Alt", position: 0) }
      let!(:store_info) do
        create(
          :store_info,
          :shopify,
          storable: existing_media,
          store_id: "gid://shopify/ProductImage/123",
          pull_time: 2.hours.ago
        )
      end

      before do
        allow(URI).to receive(:parse).with(img_url).and_return(uri_double)
        allow(uri_double).to receive(:open).and_return(test_io)
      end

      # rubocop:disable RSpec/MultipleExpectations
      it "updates existing media and reattaches image if pull_time changed" do
        job.perform(product, parsed_media)

        existing_media.reload
        expect(existing_media.alt).to eq "Test Alt"
        expect(existing_media.position).to eq 1

        store_info.reload
        expect(store_info.pull_time).to be_within(2.seconds).of(1.hour.ago)
      end
      # rubocop:enable RSpec/MultipleExpectations

      it "does not reattach image if pull_time has not changed" do
        same_time = updated_at
        store_info.update!(pull_time: Time.zone.parse(same_time))

        original_checksum = existing_media.image.blob.checksum

        job.perform(product, parsed_media)

        existing_media.reload
        expect(existing_media.image.blob.checksum).to eq original_checksum
      end
    end

    it "does nothing when product is blank" do
      expect { job.perform(nil, parsed_media) }.not_to change(product.media, :count)
    end

    it "does nothing when parsed_media is blank" do
      expect { job.perform(product, []) }.not_to change(product.media, :count)
    end
  end

  describe "#uploaded_file_data" do
    let(:uri_double) { instance_double(URI::HTTP, path: "/image.jpg") }
    let(:test_io) { instance_double(File) }

    it "returns io and filename on success" do
      allow(URI).to receive(:parse).with(img_url).and_return(uri_double)
      allow(uri_double).to receive(:open).and_return(test_io)

      result = job.send(:uploaded_file_data, img_url)
      expect(result).to eq [test_io, "image.jpg"]
    end

    it "returns nil when URI parsing raises an error" do
      invalid_url = "ht tp://invalid"
      allow(URI).to receive(:parse).and_raise(URI::InvalidURIError)

      result = job.send(:uploaded_file_data, invalid_url)
      expect(result).to be_nil
    end
  end

  describe "#download_with_retry" do
    let(:uri_double) { instance_double(URI::HTTP) }
    let(:test_io) { instance_double(File) }

    it "returns io on success" do
      allow(uri_double).to receive(:open).and_return(test_io)

      result = job.send(:download_with_retry, uri_double, img_url)
      expect(result).to eq test_io
    end

    # rubocop:disable RSpec/MultipleExpectations
    it "retries on failure and returns nil after max retries" do
      allow(uri_double).to receive(:open).and_raise(OpenURI::HTTPError.new("404 Not Found", nil))
      allow(job).to receive(:sleep)

      allow(Rails.logger).to receive(:error)

      result = job.send(:download_with_retry, uri_double, img_url)

      expect(result).to be_nil
      expect(Rails.logger).to have_received(:error).with(/Failed to download an image/)
      expect(uri_double).to have_received(:open).exactly(3).times
    end
    # rubocop:enable RSpec/MultipleExpectations
  end
end
