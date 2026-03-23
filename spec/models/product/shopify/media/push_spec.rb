# frozen_string_literal: true

require "rails_helper"

RSpec.describe Product::Shopify::Media::Push do
  include ActiveSupport::Testing::TimeHelpers

  let(:shopify_product_id) { "gid://shopify/Product/123" }
  let(:product) { create(:product_with_brands) }
  let(:api_client) { instance_spy(Shopify::Api::Client) }
  let(:first_media) { create(:media, mediaable: product, alt: "Image 1", position: 0) }
  let(:second_media) { create(:media, mediaable: product, alt: "Image 2", position: 1) }
  let(:third_media) { create(:media, mediaable: product, alt: "Image 3", position: 2) }

  before do
    ActiveStorage::Current.url_options = {host: "example.com"}
    allow(Shopify::Api::Client).to receive(:new).and_return(api_client)
    allow(first_media.image.blob.service).to receive(:exist?).with(first_media.image.blob.key).and_return(true)
    allow(second_media.image.blob.service).to receive(:exist?).with(second_media.image.blob.key).and_return(true)
    allow(third_media.image.blob.service).to receive(:exist?).with(third_media.image.blob.key).and_return(true)
    allow(api_client).to receive_messages(
      attach_media: [{"id" => "gid://shopify/MediaImage/999", "createdAt" => "2024-01-15T10:02:00Z", "updatedAt" => "2024-01-15T10:02:00Z"}],
      update_media: [{"id" => "gid://shopify/MediaImage/789", "createdAt" => "2024-01-15T10:01:00Z", "updatedAt" => "2024-01-15T11:00:00Z"}],
      reorder_media: nil,
      fetch_product: {
        "id" => shopify_product_id,
        "media" => {
          "nodes" => [
            {"id" => "gid://shopify/MediaImage/456"},
            {"id" => "gid://shopify/MediaImage/999"},
            {"id" => "gid://shopify/MediaImage/789"}
          ]
        }
      }
    )

    create(:store_info, :shopify,
      storable: first_media,
      store_id: "gid://shopify/MediaImage/456",
      checksum: first_media.image.blob.checksum,
      alt_text: first_media.alt)

    create(:store_info, :shopify,
      storable: second_media,
      store_id: "gid://shopify/MediaImage/789",
      checksum: "old_checksum",
      alt_text: "Old alt")
  end

  it "attaches new media" do
    described_class.call(product_id: product.id, product_store_id: shopify_product_id)
    expect(api_client).to have_received(:attach_media).with(shopify_product_id, kind_of(Array))
  end

  it "updates changed media" do
    described_class.call(product_id: product.id, product_store_id: shopify_product_id)
    expect(api_client).to have_received(:update_media).with(kind_of(Array))
  end

  it "reorders the product" do
    described_class.call(product_id: product.id, product_store_id: shopify_product_id)
    expect(api_client).to have_received(:reorder_media).with(shopify_product_id, kind_of(Array))
  end

  it "persists attached media info" do
    described_class.call(product_id: product.id, product_store_id: shopify_product_id)
    expect(third_media.reload.shopify_info.store_id).to eq("gid://shopify/MediaImage/999")
  end

  it "updates existing media info" do
    described_class.call(product_id: product.id, product_store_id: shopify_product_id)
    expect(second_media.reload.shopify_info.checksum).to eq(second_media.image.blob.checksum)
  end

  context "when the remote product is missing" do
    before do
      allow(api_client).to receive(:attach_media)
        .and_raise(Shopify::Api::Client::ApiError, "Failed to call the productUpdate API mutation: Product does not exist")
    end

    # rubocop:disable RSpec/MultipleExpectations
    it "cleans up Shopify store infos" do
      expect {
        described_class.call(product_id: product.id, product_store_id: shopify_product_id)
      }.not_to raise_error

      expect(product.reload.shopify_info).to be_nil
      expect(first_media.reload.store_infos.where(store_name: :shopify)).to be_empty
      expect(second_media.reload.store_infos.where(store_name: :shopify)).to be_empty
    end
    # rubocop:enable RSpec/MultipleExpectations
  end

  it "raises unexpected Shopify API errors" do
    allow(api_client).to receive(:attach_media)
      .and_raise(Shopify::Api::Client::ApiError, "Rate limit exceeded")

    expect {
      described_class.call(product_id: product.id, product_store_id: shopify_product_id)
    }.to raise_error(Shopify::Api::Client::ApiError, "Rate limit exceeded")
  end
end
