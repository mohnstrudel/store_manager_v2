# frozen_string_literal: true

require "rails_helper"

RSpec.describe Product::Shopify::Media::Push::Reorder do
  let(:product) { create(:product_with_brands) }
  let(:api_client) { instance_spy(Shopify::Api::Client) }
  let(:product_store_id) { "gid://shopify/Product/123" }
  let(:first_media) { create(:media, mediaable: product, alt: "Image 1", position: 0) }
  let(:second_media) { create(:media, mediaable: product, alt: "Image 2", position: 1) }
  let(:third_media) { create(:media, mediaable: product, alt: "Image 3", position: 2) }

  let(:shopify_product_response) do
    {
      "id" => product_store_id,
      "media" => {
        "nodes" => [
          {"id" => "gid://shopify/MediaImage/456"},
          {"id" => "gid://shopify/MediaImage/457"},
          {"id" => "gid://shopify/MediaImage/458"}
        ]
      }
    }
  end

  before do
    allow(api_client).to receive(:fetch_product).and_return(shopify_product_response)
  end

  it "reorders only media whose positions changed" do
    create(:store_info, :shopify, storable: first_media, store_id: "gid://shopify/MediaImage/456")
    create(:store_info, :shopify, storable: second_media, store_id: "gid://shopify/MediaImage/458")
    create(:store_info, :shopify, storable: third_media, store_id: "gid://shopify/MediaImage/457")

    described_class.new(
      product:,
      product_store_id:,
      api_client:
    ).call

    expect(api_client).to have_received(:reorder_media).with(product_store_id, [
      {id: "gid://shopify/MediaImage/458", newPosition: "1"},
      {id: "gid://shopify/MediaImage/457", newPosition: "2"}
    ])
  end

  it "does nothing when the local and remote order already match" do
    create(:store_info, :shopify, storable: first_media, store_id: "gid://shopify/MediaImage/456")
    create(:store_info, :shopify, storable: second_media, store_id: "gid://shopify/MediaImage/457")
    create(:store_info, :shopify, storable: third_media, store_id: "gid://shopify/MediaImage/458")

    described_class.new(
      product:,
      product_store_id:,
      api_client:
    ).call

    expect(api_client).not_to have_received(:reorder_media)
  end
end
