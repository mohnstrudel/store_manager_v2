# frozen_string_literal: true

require "rails_helper"

RSpec.describe Product::Shopify::Media::Push::Reorder do
  let(:product) { create(:product_with_brands) }
  let(:api_client) { instance_spy(Shopify::Api::Client) }
  let(:product_store_id) { "gid://shopify/Product/123" }
  let(:first_media) { create(:media, mediaable: product, alt: "Image 1", position: 0) }
  let(:second_media) { create(:media, mediaable: product, alt: "Image 2", position: 1) }
  let(:third_media) { create(:media, mediaable: product, alt: "Image 3", position: 2) }

  let(:nodes) do
    [
      {"id" => "gid://shopify/MediaImage/456"},
      {"id" => "gid://shopify/MediaImage/457"},
      {"id" => "gid://shopify/MediaImage/458"}
    ]
  end

  def reorder
    described_class.new(product:, product_store_id:, api_client:, nodes:).call
  end

  it "reorders only media whose positions changed" do
    create(:store_info, :shopify, storable: first_media, store_id: "gid://shopify/MediaImage/456")
    create(:store_info, :shopify, storable: second_media, store_id: "gid://shopify/MediaImage/458")
    create(:store_info, :shopify, storable: third_media, store_id: "gid://shopify/MediaImage/457")

    reorder

    expect(api_client).to have_received(:reorder_media).with(product_store_id, [
      {id: "gid://shopify/MediaImage/458", newPosition: "1"},
      {id: "gid://shopify/MediaImage/457", newPosition: "2"}
    ])
  end

  it "does nothing when the local and remote order already match" do
    create(:store_info, :shopify, storable: first_media, store_id: "gid://shopify/MediaImage/456")
    create(:store_info, :shopify, storable: second_media, store_id: "gid://shopify/MediaImage/457")
    create(:store_info, :shopify, storable: third_media, store_id: "gid://shopify/MediaImage/458")

    reorder

    expect(api_client).not_to have_received(:reorder_media)
  end

  it "takes the remote order from the given nodes and never fetches the product" do
    create(:store_info, :shopify, storable: first_media, store_id: "gid://shopify/MediaImage/456")
    create(:store_info, :shopify, storable: second_media, store_id: "gid://shopify/MediaImage/457")
    create(:store_info, :shopify, storable: third_media, store_id: "gid://shopify/MediaImage/458")

    described_class.new(product:, product_store_id:, api_client:, nodes: nodes.reverse).call

    expect(api_client).to have_received(:reorder_media).with(product_store_id, [
      {id: "gid://shopify/MediaImage/456", newPosition: "0"},
      {id: "gid://shopify/MediaImage/458", newPosition: "2"}
    ])
    expect(api_client).not_to have_received(:fetch_product)
  end
end
