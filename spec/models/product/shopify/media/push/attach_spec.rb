# frozen_string_literal: true

require "rails_helper"

RSpec.describe Product::Shopify::Media::Push::Attach do
  include Helpers::ShopifyMediaScenarios

  let(:product) { create(:product_with_brands) }
  let(:product_store_id) { "gid://shopify/Product/123" }
  let(:api_client) { instance_spy(Shopify::Api::Client) }
  let(:first_media) { create(:media, mediaable: product, alt: "Image 1", position: 2) }
  let(:second_media) { create(:media, mediaable: product, alt: "Image 2", position: 3) }
  let(:new_media) { [first_media, second_media] }
  let(:known_ids) { [] }
  let(:shopify_media) { [response_node(456), response_node(457)] }

  def response_node(number)
    {
      "id" => media_gid(number),
      "createdAt" => "2024-01-15T10:0#{number % 10}:00Z",
      "updatedAt" => "2024-01-15T11:0#{number % 10}:00Z"
    }
  end

  def attach
    described_class.new(product:, product_store_id:, api_client:, new_media:, known_ids:).call
  end

  before do
    ActiveStorage::Current.url_options = {host: "example.com"}
    allow(api_client).to receive(:attach_media).and_return(shopify_media)
  end

  it "attaches the new media and saves their Shopify store infos" do
    attach

    expect(api_client).to have_received(:attach_media).with(product_store_id, [
      include(originalSource: kind_of(String), alt: "Image 1", mediaContentType: "IMAGE"),
      include(originalSource: kind_of(String), alt: "Image 2", mediaContentType: "IMAGE")
    ])
    expect(first_media.reload.shopify_info).to have_attributes(
      store_id: media_gid(456),
      checksum: first_media.image.blob.checksum,
      alt_text: "Image 1",
      ext_created_at: Time.zone.parse("2024-01-15T10:06:00Z"),
      ext_updated_at: Time.zone.parse("2024-01-15T11:06:00Z"),
      push_time: be_present,
      source_url: nil
    )
    expect(second_media.reload.shopify_info.store_id).to eq(media_gid(457))
  end

  context "when the product already has media on Shopify" do
    let(:known_ids) { [media_gid(1), media_gid(2)] }
    let!(:existing_media) do
      [
        link_media(create(:media, mediaable: product, alt: "Image A", position: 0), 1),
        link_media(create(:media, mediaable: product, alt: "Image B", position: 1), 2)
      ]
    end

    it "pairs the new media with the IDs the product did not have, in response order, wherever they sit in the response" do
      allow(api_client).to receive(:attach_media).and_return(
        [response_node(3), response_node(1), response_node(2), response_node(4)]
      )

      attach

      expect(first_media.reload.shopify_info.store_id).to eq(media_gid(3))
      expect(second_media.reload.shopify_info.store_id).to eq(media_gid(4))
    end

    it "leaves the store infos of the existing media unchanged" do
      allow(api_client).to receive(:attach_media).and_return(
        [response_node(3), response_node(1), response_node(2), response_node(4)]
      )

      expect { attach }.not_to change { existing_media.map { |media| media.shopify_info.reload.attributes } }
    end

    it "ignores response nodes without an id" do
      allow(api_client).to receive(:attach_media).and_return(
        [{}, response_node(3), response_node(1), {"id" => nil}, response_node(2), response_node(4), {}]
      )

      attach

      expect(first_media.reload.shopify_info.store_id).to eq(media_gid(3))
      expect(second_media.reload.shopify_info.store_id).to eq(media_gid(4))
    end

    it "raises ApiError and saves nothing when the unknown IDs do not match the new media" do
      allow(api_client).to receive(:attach_media).and_return(
        [response_node(1), response_node(2), response_node(3)]
      )

      expect { attach }.to raise_error(Shopify::Api::Client::ApiError, /1 new media after attaching 2 images/)

      expect(StoreInfo.where(storable: new_media)).to be_empty
    end
  end
end
