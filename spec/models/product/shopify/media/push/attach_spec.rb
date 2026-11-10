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
  let(:nodes) { [] }
  let(:claimed_ids) { nodes.pluck("id") }
  let(:shopify_media) { [response_node(456), response_node(457)] }

  def response_node(number, alt: nil, status: nil)
    {
      "id" => media_gid(number),
      "alt" => alt,
      "status" => status,
      "createdAt" => "2024-01-15T10:0#{number % 10}:00Z",
      "updatedAt" => "2024-01-15T11:0#{number % 10}:00Z"
    }.compact
  end

  def attach
    described_class.new(product:, product_store_id:, api_client:, new_media:, nodes:, claimed_ids:).call
  end

  before do
    ActiveStorage::Current.url_options = {host: "example.com"}
    allow(api_client).to receive(:attach_media).and_return(shopify_media)
  end

  it "attaches the new media, saves their Shopify store infos, and returns how many it linked" do
    expect(attach).to eq(2)

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
    let(:nodes) { [response_node(1), response_node(2)] }
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

    it "raises AttachMismatch naming the product and the unknown IDs, and saves nothing, when they do not match the new media" do
      allow(api_client).to receive(:attach_media).and_return(
        [response_node(1), response_node(2), response_node(3)]
      )

      expect { attach }.to raise_error(
        Product::Shopify::Media::Push::AttachMismatch,
        /1 new media after attaching 2 images to #{Regexp.escape(product_store_id)} \(unknown IDs: #{Regexp.escape(media_gid(3))}\)/
      )

      expect(StoreInfo.where(storable: new_media)).to be_empty
    end

    it "raises AttachMismatch naming no unknown IDs when the response lists only known ones" do
      allow(api_client).to receive(:attach_media).and_return([response_node(1), response_node(2)])

      expect { attach }.to raise_error(
        Product::Shopify::Media::Push::AttachMismatch,
        /0 new media after attaching 2 images to #{Regexp.escape(product_store_id)} \(unknown IDs: none\)/
      )

      expect(StoreInfo.where(storable: new_media)).to be_empty
    end
  end

  context "when Shopify holds images that no media here is linked to" do
    let(:claimed_ids) { [media_gid(1)] }
    let(:nodes) do
      [
        response_node(1, alt: "Image 1", status: "READY"),
        response_node(7, alt: "Image 1", status: "PROCESSING"),
        response_node(8, alt: "Image 2", status: "READY")
      ]
    end

    it "links them to the new media with the same alt instead of attaching again" do
      expect(attach).to eq(2)

      expect(api_client).not_to have_received(:attach_media)
      expect(first_media.reload.shopify_info).to have_attributes(
        store_id: media_gid(7),
        checksum: first_media.image.blob.checksum,
        alt_text: "Image 1",
        ext_created_at: Time.zone.parse("2024-01-15T10:07:00Z"),
        ext_updated_at: Time.zone.parse("2024-01-15T11:07:00Z"),
        push_time: be_present
      )
      expect(second_media.reload.shopify_info.store_id).to eq(media_gid(8))
    end

    it "does not take a media another row is linked to" do
      attach

      expect(StoreInfo.shopify.where(store_id: media_gid(1))).to be_empty
    end

    context "when only some of the new media have a match" do
      let(:nodes) { [response_node(1, alt: "Image 1", status: "READY"), response_node(8, alt: "Image 2", status: "READY")] }

      before do
        allow(api_client).to receive(:attach_media).and_return(
          [response_node(1), response_node(8), response_node(9, alt: "Image 1")]
        )
      end

      it "links the matches and attaches only the others, pairing them by the IDs Shopify did not list before" do
        expect(attach).to eq(2)

        expect(api_client).to have_received(:attach_media).once.with(product_store_id, [include(alt: "Image 1")])
        expect(first_media.reload.shopify_info.store_id).to eq(media_gid(9))
        expect(second_media.reload.shopify_info.store_id).to eq(media_gid(8))
      end
    end

    context "when several new media share one alt" do
      let(:second_media) { create(:media, mediaable: product, alt: "Image 1", position: 3) }
      let(:nodes) do
        [response_node(7, alt: "Image 1", status: "READY"), response_node(8, alt: "Image 1", status: "READY")]
      end
      let(:claimed_ids) { [] }

      it "links them in the order Shopify lists the media, one media each" do
        attach

        expect(first_media.reload.shopify_info.store_id).to eq(media_gid(7))
        expect(second_media.reload.shopify_info.store_id).to eq(media_gid(8))
      end

      it "attaches the one that has no match left" do
        allow(api_client).to receive(:attach_media).and_return([response_node(7), response_node(9)])
        nodes.pop

        attach

        expect(first_media.reload.shopify_info.store_id).to eq(media_gid(7))
        expect(second_media.reload.shopify_info.store_id).to eq(media_gid(9))
      end
    end

    context "when the alt differs from the one that would be sent" do
      let(:nodes) { [response_node(7, alt: "Added in the Shopify admin", status: "READY")] }

      before do
        allow(api_client).to receive(:attach_media).and_return(
          [response_node(7), response_node(8), response_node(9)]
        )
      end

      it "leaves the media alone and attaches every new media" do
        attach

        expect(api_client).to have_received(:attach_media).once.with(product_store_id, have_attributes(size: 2))
        expect(StoreInfo.shopify.where(store_id: media_gid(7))).to be_empty
        expect(first_media.reload.shopify_info.store_id).to eq(media_gid(8))
      end
    end

    context "when the matching media failed on Shopify" do
      let(:nodes) { [response_node(7, alt: "Image 1", status: "FAILED"), response_node(8, alt: "Image 2", status: "FAILED")] }

      it "attaches the new media instead of linking failed ones" do
        allow(api_client).to receive(:attach_media).and_return([response_node(7), response_node(8), response_node(9), response_node(10)])

        attach

        expect(first_media.reload.shopify_info.store_id).to eq(media_gid(9))
        expect(second_media.reload.shopify_info.store_id).to eq(media_gid(10))
      end
    end

    context "when a new media has a blank alt" do
      let(:first_media) { create(:media, mediaable: product, alt: "", position: 2) }
      let(:nodes) { [response_node(7, alt: "#{product.title} image", status: "READY"), response_node(8, alt: "Image 2", status: "READY")] }

      it "matches the product title fallback that would be sent" do
        attach

        expect(api_client).not_to have_received(:attach_media)
        expect(first_media.reload.shopify_info.store_id).to eq(media_gid(7))
      end
    end

    context "when Shopify spaces the alt differently" do
      let(:nodes) { [response_node(7, alt: "  Image   1 ", status: "READY"), response_node(8, alt: "Image 2", status: "READY")] }

      it "still matches" do
        attach

        expect(first_media.reload.shopify_info.store_id).to eq(media_gid(7))
      end
    end
  end

  context "when a new media has a blank alt" do
    let(:first_media) { create(:media, mediaable: product, alt: "", position: 2) }

    it "sends the product title fallback as its alt and keeps the media's own alt on the store info" do
      attach

      expect(api_client).to have_received(:attach_media).with(product_store_id, [
        include(alt: "#{product.title} image"),
        include(alt: "Image 2")
      ])
      expect(first_media.reload.shopify_info.alt_text).to eq("")
    end
  end
end
