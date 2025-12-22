# frozen_string_literal: true
require "rails_helper"

RSpec.describe AttachImagesToProductsJob do
  include ActiveJob::TestHelper

  let(:subject_job) { described_class.new }
  let(:sync_woo_products_job) { instance_double(SyncWooProductsJob) }
  let(:product) { create(:product, woo_id: "123") }
  let(:img_url) { "http://example.com/image.jpg" }
  let(:parsed_product) { {woo_id: "123", images: [img_url]} }

  before do
    allow(subject_job).to receive(:attach_images).with(product, img_url)
  end

  describe "#perform" do
    it "attaches images to products" do # rubocop:todo RSpec/MultipleExpectations
      allow(SyncWooProductsJob).to receive(:new).and_return(sync_woo_products_job)
      allow(sync_woo_products_job).to receive(:get_woo_products)
      allow(sync_woo_products_job).to receive(:parse_all).and_return([parsed_product])
      allow(Product).to receive(:where).with(woo_id: ["123"]).and_return([product])

      perform_enqueued_jobs { subject_job.perform_now }

      expect(sync_woo_products_job).to have_received(:get_woo_products)
      expect(sync_woo_products_job).to have_received(:parse_all)
      expect(subject_job).to have_received(:attach_images).with(product, img_url)
    end
  end

  describe "#attach_images" do
    it "attaches an image to a product if the image is not already attached" do
      allow_any_instance_of(URI::HTTP).to receive(:open) # rubocop:todo RSpec/AnyInstance
        .and_return(StringIO.new("image data"))

      expect { described_class.new.attach_images(product, img_url) }
        .to change(product.images, :count).by(1)
    end

    it "does not attach an image if it is already present" do
      product.images.attach(io: StringIO.new("image data"), filename: File.basename(URI.parse(img_url).path))

      expect { described_class.new.attach_images(product, img_url) }
        .not_to change(product.images, :count)
    end

    # Add more tests to cover error handling cases
  end
end
