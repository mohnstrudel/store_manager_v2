# frozen_string_literal: true

require "rails_helper"

RSpec.describe Product::Shopify::Media::Push do
  include Helpers::ShopifyMediaScenarios

  let(:product_store_id) { "gid://shopify/Product/123" }
  let(:product) { create(:product_with_brands, :synced) }
  let(:api_client) { instance_spy(Shopify::Api::Client) }
  let(:storage) { ActiveStorage::Blob.service }
  let(:first_media) { create(:media, mediaable: product, alt: "Image 1", position: 0) }
  let(:second_media) { create(:media, mediaable: product, alt: "Image 2", position: 1) }
  let(:third_media) { create(:media, mediaable: product, alt: "Image 3", position: 2) }
  let(:fourth_media) { create(:media, mediaable: product, alt: "Image 4", position: 3) }

  def push
    described_class.call(product_id: product.id, product_store_id:)
  end

  def attach_attempt
    push
  rescue described_class::NotReady
    nil
  end

  def shopify_node(number, status: "READY")
    {
      "id" => media_gid(number),
      "status" => status,
      "createdAt" => "2024-01-15T10:00:00Z",
      "updatedAt" => "2024-01-15T10:00:00Z"
    }
  end

  def shopify_lists(*nodes)
    allow(api_client).to receive(:fetch_product).and_return({"id" => product_store_id, "media" => {"nodes" => nodes}})
  end

  def link(media, number, checksum: media.image.blob.checksum, alt_text: media.alt)
    create(:store_info, :shopify, storable: media, store_id: media_gid(number), checksum:, alt_text:)
  end

  before do
    ActiveStorage::Current.url_options = {host: "example.com"}
    allow(Shopify::Api::Client).to receive(:new).and_return(api_client)
    allow(storage).to receive(:exist?).and_return(true)
    allow(api_client).to receive_messages(attach_media: [], update_media: [], reorder_media: nil)
  end

  context "when the product has no media" do
    it "makes no Shopify call" do
      push

      expect(api_client).not_to have_received(:fetch_product)
      expect(api_client).not_to have_received(:attach_media)
      expect(api_client).not_to have_received(:update_media)
      expect(api_client).not_to have_received(:reorder_media)
    end
  end

  context "when new media are added to a product that already has media on Shopify" do
    let!(:first_info) { link(first_media, 1) }
    let!(:second_info) { link(second_media, 2) }

    before do
      third_media
      fourth_media
      shopify_lists(shopify_node(1), shopify_node(2))
      allow(api_client).to receive(:attach_media).and_return(
        [shopify_node(3, status: "PROCESSING"), shopify_node(1), shopify_node(2), shopify_node(4, status: "PROCESSING")]
      )
    end

    it "saves the new IDs on the new rows, wherever the new nodes sit in the response, and leaves the others alone" do
      expect { push }.to raise_error(described_class::NotReady)

      expect(third_media.reload.shopify_info).to have_attributes(store_id: media_gid(3), source_url: nil)
      expect(fourth_media.reload.shopify_info).to have_attributes(store_id: media_gid(4), source_url: nil)
      expect(first_info.reload.store_id).to eq(media_gid(1))
      expect(second_info.reload.store_id).to eq(media_gid(2))
    end

    it "raises NotReady once the store infos are committed, before any update or reorder" do
      expect { push }.to raise_error(described_class::NotReady, /#{Regexp.escape(product_store_id)}/)

      expect(StoreInfo.shopify.where(storable: [third_media, fourth_media]).count).to eq(2)
      expect(api_client).not_to have_received(:update_media)
      expect(api_client).not_to have_received(:reorder_media)
    end

    it "fetches the product once and attaches once" do
      expect { push }.to raise_error(described_class::NotReady)

      expect(api_client).to have_received(:fetch_product).with(product_store_id).once
      expect(api_client).to have_received(:attach_media).once
    end

    it "runs the storage check, the fetch, and the attach inside the product lock, in that order" do
      events = []
      allow_any_instance_of(Product).to receive(:with_lock).and_wrap_original do |original, *args, &block|
        original.call(*args) do
          events << :locked
          block.call.tap { events << :unlocked }
        end
      end
      allow(storage).to receive(:exist?) do
        events << :storage_checked
        true
      end
      allow(api_client).to receive(:fetch_product) do
        events << :fetched
        {"id" => product_store_id, "media" => {"nodes" => [shopify_node(1), shopify_node(2)]}}
      end
      allow(api_client).to receive(:attach_media) do
        events << :attached
        [shopify_node(1), shopify_node(2), shopify_node(3), shopify_node(4)]
      end

      expect { push }.to raise_error(described_class::NotReady)

      expect(events).to eq([:locked, :storage_checked, :storage_checked, :fetched, :attached, :unlocked])
    end

    context "when Shopify answers with a different number of new media than were attached" do
      before do
        allow(api_client).to receive(:attach_media).and_return([shopify_node(1), shopify_node(2), shopify_node(3)])
      end

      it "raises AttachMismatch and saves nothing" do
        expect { push }.to raise_error(described_class::AttachMismatch, /1 new media after attaching 2 images/)

        expect(StoreInfo.where(storable: [third_media, fourth_media])).to be_empty
      end
    end

    context "when the next attempt runs after the attach" do
      before do
        attach_attempt
        shopify_lists(shopify_node(1), shopify_node(2), shopify_node(3), shopify_node(4))
      end

      it "attaches nothing again because every row now has an ID" do
        push

        expect(api_client).to have_received(:attach_media).once
      end

      it "sends no update when nothing changed and no reorder when the order matches" do
        push

        expect(api_client).not_to have_received(:update_media)
        expect(api_client).not_to have_received(:reorder_media)
      end

      it "reorders when Shopify lists the media in another order" do
        shopify_lists(shopify_node(3), shopify_node(4), shopify_node(1), shopify_node(2))

        push

        expect(api_client).to have_received(:reorder_media).with(product_store_id, [
          {id: media_gid(1), newPosition: "0"},
          {id: media_gid(2), newPosition: "1"},
          {id: media_gid(3), newPosition: "2"},
          {id: media_gid(4), newPosition: "3"}
        ])
      end
    end
  end

  context "when a new media file is not in storage yet" do
    before do
      link(first_media, 1)
      third_media
      allow(storage).to receive(:exist?).with(third_media.image.blob.key).and_return(false)
      shopify_lists(shopify_node(1))
    end

    it "raises NotReady before any Shopify call and saves nothing" do
      expect { push }.to raise_error(described_class::NotReady, /#{third_media.id}/)

      expect(api_client).not_to have_received(:fetch_product)
      expect(api_client).not_to have_received(:attach_media)
      expect(third_media.reload.shopify_info).to be_nil
    end
  end

  context "when every media already has a Shopify ID" do
    let!(:first_info) { link(first_media, 1) }
    let!(:second_info) { link(second_media, 2, checksum: "old_checksum", alt_text: "Old alt") }

    context "when every Shopify media is READY" do
      before { shopify_lists(shopify_node(2), shopify_node(1)) }

      it "updates the changed media, then reorders, from one fetch and without attaching" do
        push

        expect(api_client).to have_received(:update_media).with([
          {id: media_gid(2), alt: "Image 2", originalSource: kind_of(String)}
        ]).ordered
        expect(api_client).to have_received(:reorder_media).with(product_store_id, [
          {id: media_gid(1), newPosition: "0"},
          {id: media_gid(2), newPosition: "1"}
        ]).ordered
        expect(api_client).to have_received(:fetch_product).once
        expect(api_client).not_to have_received(:attach_media)
        expect(second_info.reload).to have_attributes(checksum: second_media.image.blob.checksum, alt_text: "Image 2")
      end

      it "leaves source_url untouched on the rows it updates" do
        second_info.update!(source_url: cdn_url("two"))

        push

        expect(second_info.reload.source_url).to eq(cdn_url("two"))
      end
    end

    context "when Shopify lists media without an id" do
      before { shopify_lists({}, shopify_node(1), {}, shopify_node(2)) }

      it "ignores them when checking readiness" do
        expect { push }.not_to raise_error

        expect(api_client).to have_received(:update_media)
      end
    end

    context "when a Shopify media is still processing" do
      before { shopify_lists(shopify_node(1), shopify_node(2, status: "PROCESSING")) }

      it "raises NotReady naming it, before any update or reorder" do
        expect { push }.to raise_error(described_class::NotReady, /#{Regexp.escape(media_gid(2))}/)

        expect(api_client).not_to have_received(:update_media)
        expect(api_client).not_to have_received(:reorder_media)
      end
    end

    context "when a Shopify media was uploaded but not processed" do
      before { shopify_lists(shopify_node(1, status: "UPLOADED"), shopify_node(2)) }

      it "raises NotReady" do
        expect { push }.to raise_error(described_class::NotReady, /#{Regexp.escape(media_gid(1))}/)
      end
    end

    context "when a Shopify media failed" do
      before do
        shopify_lists(shopify_node(1, status: "PROCESSING"), shopify_node(2, status: "FAILED"))
      end

      it "raises MediaFailed naming the failed IDs, before any update or reorder" do
        expect { push }.to raise_error(described_class::MediaFailed, /#{Regexp.escape(media_gid(2))}/)

        expect(api_client).not_to have_received(:update_media)
        expect(api_client).not_to have_received(:reorder_media)
      end

      it "keeps the failed media's store info" do
        expect { push }.to raise_error(described_class::MediaFailed)

        expect(second_info.reload.store_id).to eq(media_gid(2))
      end
    end
  end

  context "when the remote product is missing" do
    before do
      link(first_media, 1)
      link(second_media, 2)
      third_media
    end

    it "cleans up Shopify store infos when the attach reports it" do
      shopify_lists(shopify_node(1), shopify_node(2))
      allow(api_client).to receive(:attach_media)
        .and_raise(Shopify::Api::Client::ApiError, "Failed to call the productUpdate API mutation: Product does not exist")

      expect { push }.not_to raise_error

      expect(product.reload.shopify_info).to be_nil
      expect(StoreInfo.shopify.where(storable_type: "Media", storable_id: [first_media.id, second_media.id])).to be_empty
    end

    it "cleans up Shopify store infos when Shopify no longer lists the product" do
      allow(api_client).to receive(:fetch_product).and_return(nil)

      expect { push }.not_to raise_error

      expect(product.reload.shopify_info).to be_nil
      expect(StoreInfo.shopify.where(storable_type: "Media", storable_id: [first_media.id, second_media.id])).to be_empty
      expect(api_client).not_to have_received(:attach_media)
    end
  end

  it "raises unexpected Shopify API errors" do
    link(first_media, 1)
    third_media
    shopify_lists(shopify_node(1))
    allow(api_client).to receive(:attach_media)
      .and_raise(Shopify::Api::Client::ApiError, "Rate limit exceeded")

    expect { push }.to raise_error(Shopify::Api::Client::ApiError, "Rate limit exceeded")
  end
end
