# frozen_string_literal: true

require "rails_helper"

RSpec.describe Woo::AttachImagesToProductsJob do
  include ActiveJob::TestHelper

  let(:subject_job) { described_class.new }
  let(:client) { instance_double(Woo::Api::Client) }
  let(:product) { create(:product, woo_store_id: "123") }
  let(:img_url) { "http://example.com/image.jpg" }
  let(:parsed_product) { {woo_id: "123", images: [img_url]} }

  before do
    allow(subject_job).to receive(:attach_images).with(product, img_url)
  end

  describe "#perform" do
    it "attaches images to products" do # rubocop:todo RSpec/MultipleExpectations
      allow(Woo::Api::Client).to receive(:new).and_return(client)
      allow(client).to receive(:fetch_products).with(Woo::PullProductsJob::PRODUCTS_SIZE).and_return([{id: 123}])
      allow(Product::Woo::Parser).to receive(:parse_all).with([{id: 123}]).and_return([parsed_product])
      allow(Product).to receive(:where_woo_ids).with(["123"]).and_return([product])

      perform_enqueued_jobs { subject_job.perform_now }

      expect(client).to have_received(:fetch_products)
      expect(Product::Woo::Parser).to have_received(:parse_all)
      expect(Product).to have_received(:where_woo_ids).with(["123"])
      expect(subject_job).to have_received(:attach_images).with(product, img_url)
    end
  end

  describe "#attach_images" do
    it "attaches an image to a product if the image is not already attached" do
      allow_any_instance_of(URI::HTTP).to receive(:open) # rubocop:todo RSpec/AnyInstance
        .and_return(StringIO.new("image data"))

      expect { described_class.new.attach_images(product, img_url) }
        .to change(product.media, :count).by(1)
    end

    it "does not attach an image if it is already present" do
      product.media.create(image: io_for(img_url))

      expect { described_class.new.attach_images(product, img_url) }
        .not_to change(product.media, :count)
    end
  end

  def io_for(url)
    filename = File.basename(URI.parse(url).path)
    {io: StringIO.new("image data"), filename:}
  end
end
