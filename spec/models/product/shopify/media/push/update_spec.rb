# frozen_string_literal: true

require "rails_helper"

RSpec.describe Product::Shopify::Media::Push::Update do
  include ActiveSupport::Testing::TimeHelpers

  let(:product) { create(:product_with_brands) }
  let(:api_client) { instance_spy(Shopify::Api::Client) }
  let(:media) { create(:media, mediaable: product, alt: "Updated Alt") }
  let(:shopify_info) do
    create(:store_info, :shopify,
      storable: media,
      store_id: "gid://shopify/MediaImage/789",
      checksum: "old_checksum",
      alt_text: "Old Alt")
  end

  let(:updated_shopify_media) do
    [
      {"id" => "gid://shopify/MediaImage/789", "createdAt" => "2024-01-10T10:00:00Z", "updatedAt" => "2024-01-15T11:00:00Z"}
    ]
  end

  before do
    ActiveStorage::Current.url_options = {host: "example.com"}
    shopify_info
    allow(media.image.blob.service).to receive(:exist?).with(media.image.blob.key).and_return(true)
    allow(api_client).to receive(:update_media).and_return(updated_shopify_media)
  end

  # rubocop:disable RSpec/MultipleExpectations
  it "updates changed media and syncs the Shopify store info" do
    described_class.new(
      product:,
      api_client:,
      existing_media: [media.reload]
    ).call

    expect(api_client).to have_received(:update_media).with([
      include(id: "gid://shopify/MediaImage/789", originalSource: kind_of(String), alt: "Updated Alt")
    ])

    shopify_info.reload
    expect(shopify_info.checksum).to eq(media.image.blob.checksum)
    expect(shopify_info.alt_text).to eq("Updated Alt")
    expect(shopify_info.ext_created_at).to eq(Time.zone.parse("2024-01-10T10:00:00Z"))
    expect(shopify_info.ext_updated_at).to eq(Time.zone.parse("2024-01-15T11:00:00Z"))
    expect(shopify_info.push_time).to be_present
  end
  # rubocop:enable RSpec/MultipleExpectations
end
