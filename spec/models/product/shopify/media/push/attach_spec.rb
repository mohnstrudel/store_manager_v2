# frozen_string_literal: true

require "rails_helper"

RSpec.describe Product::Shopify::Media::Push::Attach do
  include ActiveSupport::Testing::TimeHelpers

  let(:product) { create(:product_with_brands) }
  let(:product_store_id) { "gid://shopify/Product/123" }
  let(:api_client) { instance_spy(Shopify::Api::Client) }
  let(:first_media) { create(:media, mediaable: product, alt: "Image 1") }
  let(:second_media) { create(:media, mediaable: product, alt: "Image 2") }
  let(:new_media) { [first_media, second_media] }
  let(:shopify_media) do
    [
      {"id" => "gid://shopify/MediaImage/456", "createdAt" => "2024-01-15T10:00:00Z", "updatedAt" => "2024-01-15T10:00:00Z"},
      {"id" => "gid://shopify/MediaImage/457", "createdAt" => "2024-01-15T10:01:00Z", "updatedAt" => "2024-01-15T10:01:00Z"}
    ]
  end

  before do
    ActiveStorage::Current.url_options = {host: "example.com"}
    allow(first_media.image.blob.service).to receive(:exist?).with(first_media.image.blob.key).and_return(true)
    allow(second_media.image.blob.service).to receive(:exist?).with(second_media.image.blob.key).and_return(true)
    allow(api_client).to receive(:attach_media).and_return(shopify_media)
  end

  # rubocop:disable RSpec/MultipleExpectations
  it "attaches media and saves Shopify store infos" do
    described_class.new(
      product:,
      product_store_id:,
      api_client:,
      new_media:
    ).call

    expect(api_client).to have_received(:attach_media).with(product_store_id, kind_of(Array)) do |_id, payload|
      expect(payload).to include(
        include(originalSource: kind_of(String), alt: "Image 1", mediaContentType: "IMAGE"),
        include(originalSource: kind_of(String), alt: "Image 2", mediaContentType: "IMAGE")
      )
    end

    expect(first_media.reload.shopify_info.store_id).to eq("gid://shopify/MediaImage/456")
    expect(second_media.reload.shopify_info.store_id).to eq("gid://shopify/MediaImage/457")
    expect(first_media.shopify_info.push_time).to be_present
  end
  # rubocop:enable RSpec/MultipleExpectations
end
