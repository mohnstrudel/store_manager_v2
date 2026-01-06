# frozen_string_literal: true

require "rails_helper"

RSpec.describe Shopify::AddImageJob do
  describe "#perform" do
    let(:shopify_product_id) { "gid://shopify/Product/123" }
    let(:product) { create(:product_with_brands) }
    let(:product_id) { product.id }
    let(:api_client) { instance_spy(Shopify::ApiClient) }

    let(:media1) { create(:media, :for_product, alt: "Image 1", position: 0) }
    let(:media2) { create(:media, :for_product, alt: "Image 2", position: 1) }
    let(:media3) { create(:media, :for_product, alt: "Image 3", position: 2) }

    let(:created_shopify_media) do
      [
        {"id" => "gid://shopify/MediaImage/456", "alt" => "Image 1", "mediaContentType" => "IMAGE", "status" => "UPLOADED"},
        {"id" => "gid://shopify/MediaImage/457", "alt" => "Image 2", "mediaContentType" => "IMAGE", "status" => "UPLOADED"},
        {"id" => "gid://shopify/MediaImage/458", "alt" => "Image 3", "mediaContentType" => "IMAGE", "status" => "UPLOADED"}
      ]
    end

    before do
      # Set ActiveStorage URL options for test environment
      ActiveStorage::Current.url_options = {host: "example.com"}

      product.media << [media1, media2, media3]
      allow(Shopify::ApiClient).to receive(:new).and_return(api_client)
      allow(api_client).to receive(:add_images).with(shopify_product_id, kind_of(Array)).and_return(created_shopify_media)
      allow(api_client).to receive(:reorder_media).with(shopify_product_id, kind_of(Array))

      # Stub file availability check - files are immediately available
      allow(media1.image.blob.service).to receive(:exist?).with(media1.image.blob.key).and_return(true)
      allow(media2.image.blob.service).to receive(:exist?).with(media2.image.blob.key).and_return(true)
      allow(media3.image.blob.service).to receive(:exist?).with(media3.image.blob.key).and_return(true)
    end

    it "finds the product by ID" do
      allow(Product).to receive(:find).with(product_id).and_return(product)
      described_class.perform_now(shopify_product_id, product_id)
      expect(Product).to have_received(:find).with(product_id)
    end

    it "creates API client" do
      described_class.perform_now(shopify_product_id, product_id)
      expect(Shopify::ApiClient).to have_received(:new)
    end

    it "returns early if product has no media" do
      product_with_no_media = create(:product_with_brands)
      allow(Product).to receive(:find).and_return(product_with_no_media)

      described_class.perform_now(shopify_product_id, product_with_no_media.id)

      expect(api_client).not_to have_received(:add_images)
    end

    it "filters out media already synced to Shopify" do
      # Mark media3 as already synced
      media3.store_infos.create!(store_name: :shopify, store_id: "gid://shopify/MediaImage/999")

      # Update mock to return only 2 items since only 2 are being uploaded
      allow(api_client).to receive(:add_images).with(shopify_product_id, kind_of(Array)).and_return(
        [
          {"id" => "gid://shopify/MediaImage/456", "alt" => "Image 1", "mediaContentType" => "IMAGE", "status" => "UPLOADED"},
          {"id" => "gid://shopify/MediaImage/457", "alt" => "Image 2", "mediaContentType" => "IMAGE", "status" => "UPLOADED"}
        ]
      )

      described_class.perform_now(shopify_product_id, product_id)

      expect(api_client).to have_received(:add_images) do |_product_id, images_input|
        expect(images_input.size).to eq(2)
        expect(images_input.map { |i| i[:alt] }).to eq(["Image 1", "Image 2"])
      end
    end

    it "uploads unsynced media with correct data structure" do
      described_class.perform_now(shopify_product_id, product_id)

      expect(api_client).to have_received(:add_images).with(shopify_product_id, kind_of(Array)) do |_id, images_input|
        expect(images_input.first).to include(
          originalSource: kind_of(String),
          alt: "Image 1",
          mediaContentType: "IMAGE"
        )
      end
    end

    it "saves Shopify media IDs to StoreInfo" do
      expect {
        described_class.perform_now(shopify_product_id, product_id)
      }.to change { media1.store_infos.where(store_name: :shopify).count }.by(1)

      store_info = media1.store_infos.find_by(store_name: :shopify)
      expect(store_info.store_id).to eq("gid://shopify/MediaImage/456")
    end

    it "calls reorder_media_on_shopify after upload" do
      # Mark all media as synced for reorder (add_images will create the store_infos)
      described_class.perform_now(shopify_product_id, product_id)

      expect(api_client).to have_received(:reorder_media).with(shopify_product_id, kind_of(Array))
    end

    it "returns early if all media is already synced" do
      media1.store_infos.create!(store_name: :shopify, store_id: "gid://shopify/MediaImage/456")
      media2.store_infos.create!(store_name: :shopify, store_id: "gid://shopify/MediaImage/457")
      media3.store_infos.create!(store_name: :shopify, store_id: "gid://shopify/MediaImage/458")

      described_class.perform_now(shopify_product_id, product_id)

      expect(api_client).not_to have_received(:add_images)
    end

    context "when file is not immediately available" do
      before do
        # File becomes available after 2 checks
        allow(media1.image.blob.service).to receive(:exist?).with(media1.image.blob.key).and_return(false, true)
        allow(media2.image.blob.service).to receive(:exist?).with(media2.image.blob.key).and_return(false, true)
        allow(media3.image.blob.service).to receive(:exist?).with(media3.image.blob.key).and_return(false, true)
      end

      it "waits until file is available" do
        expect {
          described_class.perform_now(shopify_product_id, product_id)
        }.not_to raise_error

        expect(media1.image.blob.service).to have_received(:exist?).with(media1.image.blob.key).at_least(2).times
      end
    end

    context "when file is not available after timeout" do
      before do
        allow(media1.image.blob.service).to receive(:exist?).with(media1.image.blob.key).and_return(false)
        allow(media2.image.blob.service).to receive(:exist?).with(media2.image.blob.key).and_return(false)
        allow(media3.image.blob.service).to receive(:exist?).with(media3.image.blob.key).and_return(false)
      end

      it "raises timeout error" do
        allow_any_instance_of(described_class).to receive(:wait_until_file_is_available).and_raise(
          Timeout::Error, "File was not uploaded to R2 in 300 seconds"
        )

        expect {
          described_class.perform_now(shopify_product_id, product_id)
        }.to raise_error(Timeout::Error, /File was not uploaded to R2/)
      end
    end
  end

  describe "#reorder_media_on_shopify" do
    let(:shopify_product_id) { "gid://shopify/Product/123" }
    let(:product) { create(:product_with_brands) }
    let(:api_client) { instance_spy(Shopify::ApiClient) }
    let(:media1) { create(:media, :for_product, alt: "Image 1", position: 0) }
    let(:media2) { create(:media, :for_product, alt: "Image 2", position: 1) }
    let(:media3) { create(:media, :for_product, alt: "Image 3", position: 2) }

    before do
      product.media << [media1, media2, media3]
    end

    it "builds correct moves array mapping local position to Shopify media ID" do
      media1.store_infos.create!(store_name: :shopify, store_id: "gid://shopify/MediaImage/456")
      media2.store_infos.create!(store_name: :shopify, store_id: "gid://shopify/MediaImage/457")
      media3.store_infos.create!(store_name: :shopify, store_id: "gid://shopify/MediaImage/458")

      job = described_class.new
      job.send(:reorder_media_on_shopify, product, shopify_product_id, api_client)

      expect(api_client).to have_received(:reorder_media).with(shopify_product_id, [
        {id: "gid://shopify/MediaImage/456", newPosition: 0},
        {id: "gid://shopify/MediaImage/457", newPosition: 1},
        {id: "gid://shopify/MediaImage/458", newPosition: 2}
      ])
    end

    it "orders media by local position" do
      # Create media out of order
      media3.update(position: 2)
      media1.update(position: 0)
      media2.update(position: 1)

      media1.store_infos.create!(store_name: :shopify, store_id: "gid://shopify/MediaImage/456")
      media2.store_infos.create!(store_name: :shopify, store_id: "gid://shopify/MediaImage/457")
      media3.store_infos.create!(store_name: :shopify, store_id: "gid://shopify/MediaImage/458")

      job = described_class.new
      job.send(:reorder_media_on_shopify, product, shopify_product_id, api_client)

      expect(api_client).to have_received(:reorder_media).with(shopify_product_id, [
        {id: "gid://shopify/MediaImage/456", newPosition: 0},
        {id: "gid://shopify/MediaImage/457", newPosition: 1},
        {id: "gid://shopify/MediaImage/458", newPosition: 2}
      ])
    end

    it "returns early if no media has Shopify IDs" do
      job = described_class.new
      job.send(:reorder_media_on_shopify, product, shopify_product_id, api_client)

      expect(api_client).not_to have_received(:reorder_media)
    end

    it "only includes media that have been synced to Shopify" do
      media1.store_infos.create!(store_name: :shopify, store_id: "gid://shopify/MediaImage/456")
      # media2 not synced
      media3.store_infos.create!(store_name: :shopify, store_id: "gid://shopify/MediaImage/458")

      job = described_class.new
      job.send(:reorder_media_on_shopify, product, shopify_product_id, api_client)

      expect(api_client).to have_received(:reorder_media).with(shopify_product_id, [
        {id: "gid://shopify/MediaImage/456", newPosition: 0},
        {id: "gid://shopify/MediaImage/458", newPosition: 2}
      ])
    end
  end

  describe "#save_shopify_media_ids" do
    let(:media1) { create(:media, :for_product) }
    let(:media2) { create(:media, :for_product) }
    let(:shopify_media) do
      [
        {"id" => "gid://shopify/MediaImage/456", "alt" => "Image 1"},
        {"id" => "gid://shopify/MediaImage/457", "alt" => "Image 2"}
      ]
    end

    it "creates StoreInfo records for each media" do
      local_media = [media1, media2]

      expect {
        job = described_class.new
        job.send(:save_shopify_media_ids, local_media, shopify_media)
      }.to change { StoreInfo.where(store_name: :shopify).count }.by(2)
    end

    it "pairs local media with Shopify media by index" do
      local_media = [media1, media2]

      job = described_class.new
      job.send(:save_shopify_media_ids, local_media, shopify_media)

      expect(media1.store_infos.find_by(store_name: :shopify).store_id).to eq("gid://shopify/MediaImage/456")
      expect(media2.store_infos.find_by(store_name: :shopify).store_id).to eq("gid://shopify/MediaImage/457")
    end

    it "sets store_name to :shopify" do
      local_media = [media1]

      job = described_class.new
      job.send(:save_shopify_media_ids, local_media, shopify_media)

      expect(media1.store_infos.last.store_name).to eq("shopify")
    end
  end
end
