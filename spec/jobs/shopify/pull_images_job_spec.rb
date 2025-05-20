require "rails_helper"
require "open-uri"

describe Shopify::PullImagesJob do
  include ActiveJob::TestHelper

  let(:job) { described_class.new }
  let(:product) { create(:product) }
  let(:img_url) { "http://example.com/image.jpg" }
  let(:parsed_images) { [{"src" => img_url}] }
  let(:active_storage_attachment) { instance_double(ActiveStorage::Attachment) }
  let(:io_mock) { instance_double(StringIO) }
  let(:uri_double) { instance_double(URI::HTTP, path: "/image.jpg") }
  let(:md5_digest) { instance_double(Digest::MD5, base64digest: "checksum123") }

  describe "#perform" do
    it "calls attach_image for each image if product and images exist" do
      allow(job).to receive(:attach_image)
      job.perform(product, parsed_images)
      expect(job).to have_received(:attach_image).with(product, img_url)
    end

    it "does nothing when product is blank" do
      allow(job).to receive(:attach_image)
      job.perform(nil, parsed_images)
      expect(job).not_to have_received(:attach_image)
    end

    it "does nothing when parsed_images is blank" do
      allow(job).to receive(:attach_image)
      job.perform(product, [])
      expect(job).not_to have_received(:attach_image)
    end
  end

  describe "#attach_image" do
    before do
      # Mock URI parsing
      allow(URI).to receive(:parse).with(img_url).and_return(uri_double)
      allow(File).to receive(:basename).with("/image.jpg").and_return("image.jpg")

      # Mock URI opening to return our io_mock
      allow(uri_double).to receive(:open).and_return(io_mock)

      # Mock MD5 calculation
      allow(Digest::MD5).to receive(:file).with(io_mock).and_return(md5_digest)

      # Mock ActiveStorage methods
      allow(product.images).to receive(:find_by).with(checksum: "checksum123").and_return(nil)
      allow(product.images).to receive(:attach)
    end

    it "attaches an image to the product if not a duplicate" do
      job.send(:attach_image, product, img_url)
      expect(product.images).to have_received(:attach).with(io: io_mock, filename: "image.jpg")
    end

    it "does not attach a duplicate image" do
      allow(product.images.blobs).to receive(:find_by).with(checksum: "checksum123").and_return(active_storage_attachment)

      job.send(:attach_image, product, img_url)
      expect(product.images).not_to have_received(:attach)
    end

    it "logs an error when download fails" do
      allow(uri_double).to receive(:open).and_raise(OpenURI::HTTPError.new("404 Not Found", nil))
      allow(job).to receive(:sleep) # Don't actually sleep in tests
      allow(Rails.logger).to receive(:error)

      job.send(:attach_image, product, img_url)
      expect(Rails.logger).to have_received(:error).with(/Failed to download an image/)
    end
  end
end
