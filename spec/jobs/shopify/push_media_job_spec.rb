# frozen_string_literal: true

require "rails_helper"

RSpec.describe Shopify::PushMediaJob do
  include ActiveJob::TestHelper
  include ActiveSupport::Testing::TimeHelpers

  describe ".perform_later" do
    let(:shopify_product_id) { "gid://shopify/Product/123" }
    let(:product) { create(:product_with_brands) }

    it "enqueues the job with correct arguments" do
      expect {
        described_class.perform_later(shopify_product_id, product.id)
      }.to have_enqueued_job(described_class).with(shopify_product_id, product.id).exactly(:once)
    end
  end

  describe "#perform_now" do
    let(:shopify_product_id) { "gid://shopify/Product/123" }
    let(:product) { create(:product_with_brands) }
    let(:product_id) { product.id }
    let(:api_client) { instance_spy(Shopify::Api::Client) }

    let(:first_media) { create(:media, :for_product, alt: "Image 1", position: 0) }
    let(:second_media) { create(:media, :for_product, alt: "Image 2", position: 1) }
    let(:third_media) { create(:media, :for_product, alt: "Image 3", position: 2) }

    let(:created_shopify_media) do
      [
        {"id" => "gid://shopify/MediaImage/456", "alt" => "Image 1", "createdAt" => "2024-01-15T10:00:00Z", "updatedAt" => "2024-01-15T10:00:00Z"},
        {"id" => "gid://shopify/MediaImage/457", "alt" => "Image 2", "createdAt" => "2024-01-15T10:01:00Z", "updatedAt" => "2024-01-15T10:01:00Z"},
        {"id" => "gid://shopify/MediaImage/458", "alt" => "Image 3", "createdAt" => "2024-01-15T10:02:00Z", "updatedAt" => "2024-01-15T10:02:00Z"}
      ]
    end

    let(:updated_shopify_media) do
      [
        {"id" => "gid://shopify/MediaImage/789", "alt" => "Updated Image 1", "createdAt" => "2024-01-10T10:00:00Z", "updatedAt" => "2024-01-15T11:00:00Z"}
      ]
    end

    let(:shopify_product_response) do
      {
        "id" => shopify_product_id,
        "title" => "Test Product",
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
      # Set ActiveStorage URL options for test environment
      ActiveStorage::Current.url_options = {host: "example.com"}

      product.media << [first_media, second_media, third_media]
      allow(Shopify::Api::Client).to receive(:new).and_return(api_client)
      allow(api_client).to receive(:attach_media).with(shopify_product_id, kind_of(Array)).and_return(created_shopify_media)
      allow(api_client).to receive(:update_media).with(kind_of(Array)).and_return(updated_shopify_media)
      allow(api_client).to receive(:reorder_media).with(shopify_product_id, kind_of(Array))
      allow(api_client).to receive(:fetch_product).with(shopify_product_id).and_return(shopify_product_response)

      # Stub file availability check - files are immediately available
      allow(first_media.image.blob.service).to receive(:exist?).with(first_media.image.blob.key).and_return(true)
      allow(second_media.image.blob.service).to receive(:exist?).with(second_media.image.blob.key).and_return(true)
      allow(third_media.image.blob.service).to receive(:exist?).with(third_media.image.blob.key).and_return(true)
    end

    it "finds the product by ID with includes" do
      scope = instance_spy(ActiveRecord::Relation)

      allow(Product).to receive(:for_media_sync).and_return(scope)
      allow(scope).to receive(:includes).with(media: [:image_attachment, :image_blob, :shopify_info]).and_return(scope)
      allow(scope).to receive(:find).with(product_id).and_return(product)

      described_class.perform_now(product_id, shopify_product_id)

      expect(Product).to have_received(:for_media_sync)
    end

    it "creates API client" do
      described_class.perform_now(product_id, shopify_product_id)
      expect(Shopify::Api::Client).to have_received(:new)
    end

    it "returns early if product has no media" do
      product_with_no_media = create(:product_with_brands)
      allow(Product).to receive(:find).and_return(product_with_no_media)

      described_class.perform_now(product_with_no_media.id, shopify_product_id)

      expect(api_client).not_to have_received(:attach_media)
      expect(api_client).not_to have_received(:update_media)
    end

    it "attaches new media to Shopify" do
      described_class.perform_now(product_id, shopify_product_id)

      expect(api_client).to have_received(:attach_media).with(shopify_product_id, kind_of(Array))
    end

    it "calls reorder_media_on_shopify after upload" do
      # Mark all media as synced for reorder check
      first_media.store_infos.create!(store_name: :shopify, store_id: "gid://shopify/MediaImage/456", checksum: first_media.image.blob.checksum, alt_text: first_media.alt)
      second_media.store_infos.create!(store_name: :shopify, store_id: "gid://shopify/MediaImage/457", checksum: second_media.image.blob.checksum, alt_text: second_media.alt)
      third_media.store_infos.create!(store_name: :shopify, store_id: "gid://shopify/MediaImage/458", checksum: third_media.image.blob.checksum, alt_text: third_media.alt)

      described_class.perform_now(product_id, shopify_product_id)

      # Verify that fetch_product was called as part of the reordering check
      expect(api_client).to have_received(:fetch_product).with(shopify_product_id)
    end

    it "returns early if all media is already synced and unchanged" do
      first_media.store_infos.create!(store_name: :shopify, store_id: "gid://shopify/MediaImage/456", checksum: first_media.image.blob.checksum, alt_text: first_media.alt)
      second_media.store_infos.create!(store_name: :shopify, store_id: "gid://shopify/MediaImage/457", checksum: second_media.image.blob.checksum, alt_text: second_media.alt)
      third_media.store_infos.create!(store_name: :shopify, store_id: "gid://shopify/MediaImage/458", checksum: third_media.image.blob.checksum, alt_text: third_media.alt)

      described_class.perform_now(product_id, shopify_product_id)

      expect(api_client).not_to have_received(:attach_media)
      expect(api_client).not_to have_received(:update_media)
    end

    context "when file is not immediately available" do
      before do
        # File becomes available after 2 checks
        allow(first_media.image.blob.service).to receive(:exist?).with(first_media.image.blob.key).and_return(false, true)
        allow(second_media.image.blob.service).to receive(:exist?).with(second_media.image.blob.key).and_return(false, true)
        allow(third_media.image.blob.service).to receive(:exist?).with(third_media.image.blob.key).and_return(false, true)
      end

      it "waits until file is available" do
        expect {
          described_class.perform_now(product_id, shopify_product_id)
        }.not_to raise_error

        expect(first_media.image.blob.service).to have_received(:exist?).with(first_media.image.blob.key).at_least(2).times
      end
    end

    context "when file is not available after timeout" do
      before do
        allow(first_media.image.blob.service).to receive(:exist?).with(first_media.image.blob.key).and_return(false)
        allow(second_media.image.blob.service).to receive(:exist?).with(second_media.image.blob.key).and_return(false)
        allow(third_media.image.blob.service).to receive(:exist?).with(third_media.image.blob.key).and_return(false)
      end

      it "raises timeout error" do
        allow_any_instance_of(described_class).to receive(:wait_until_file_is_available).and_raise(
          RuntimeError, "File was not uploaded to R2 in 600 seconds"
        )

        expect {
          described_class.perform_now(product_id, shopify_product_id)
        }.to raise_error(RuntimeError, /File was not uploaded to R2/)
      end
    end

    context "when product does not exist on Shopify" do
      before do
        # Product and media have existing Shopify store_infos
        product.shopify_info.update!(store_id: shopify_product_id)
        first_media.store_infos.create!(store_name: :shopify, store_id: "gid://shopify/MediaImage/456", checksum: first_media.image.blob.checksum, alt_text: first_media.alt)
        second_media.store_infos.create!(store_name: :shopify, store_id: "gid://shopify/MediaImage/457", checksum: second_media.image.blob.checksum, alt_text: second_media.alt)

        # Override the parent stub to raise an error (must match the with() clause to override)
        allow(api_client).to receive(:attach_media).with(shopify_product_id, kind_of(Array))
          .and_raise(Shopify::Api::Client::ApiError, "Failed to call the productUpdate API mutation: Product does not exist")
      end

      it "removes product's Shopify store_info" do
        expect {
          described_class.perform_now(product_id, shopify_product_id)
        }.to change { product.store_infos.where(store_name: :shopify).count }.from(1).to(0)
      end

      it "removes all media's Shopify store_infos" do
        expect {
          described_class.perform_now(product_id, shopify_product_id)
        }.to change { first_media.store_infos.where(store_name: :shopify).count }.from(1).to(0)
          .and change { second_media.store_infos.where(store_name: :shopify).count }.from(1).to(0)
      end

      it "does not raise error after cleanup" do
        expect { described_class.perform_now(product_id, shopify_product_id) }.not_to raise_error
      end
    end

    context "when media has changed" do
      before do
        # Media was already synced but has changed
        first_media.store_infos.create!(
          store_name: :shopify,
          store_id: "gid://shopify/MediaImage/789",
          checksum: "old_checksum",
          alt_text: "Old alt text"
        )
        second_media.store_infos.create!(
          store_name: :shopify,
          store_id: "gid://shopify/MediaImage/457",
          checksum: second_media.image.blob.checksum,
          alt_text: second_media.alt
        )
        # third_media is new (no store_info)
      end

      it "updates existing media with changes" do
        described_class.perform_now(product_id, shopify_product_id)

        expect(api_client).to have_received(:update_media).with(kind_of(Array)) do |file_updates|
          expect(file_updates.size).to eq(1)
          expect(file_updates.first[:id]).to eq("gid://shopify/MediaImage/789")
          expect(file_updates.first[:alt]).to eq("Image 1")
        end
      end

      it "attaches new media" do
        described_class.perform_now(product_id, shopify_product_id)

        expect(api_client).to have_received(:attach_media).with(shopify_product_id, kind_of(Array)) do |_id, media_input|
          expect(media_input.size).to eq(1)
          expect(media_input.first[:alt]).to eq("Image 3")
        end
      end
    end
  end

  describe "#media_changed?" do
    let(:media) { create(:media, :for_product, alt: "Test Alt") }
    let(:shopify_info) { create(:store_info, :shopify, storable: media, checksum: media.image.blob.checksum, alt_text: "Test Alt") }

    it "returns false when checksum and alt_text match" do
      result = described_class.new.send(:media_changed?, media, shopify_info)
      expect(result).to be false
    end

    it "returns true when alt_text differs" do
      shopify_info.update!(alt_text: "Different Alt")
      result = described_class.new.send(:media_changed?, media, shopify_info)
      expect(result).to be true
    end

    it "returns true when checksum differs" do
      shopify_info.update!(checksum: "different_checksum")
      result = described_class.new.send(:media_changed?, media, shopify_info)
      expect(result).to be true
    end

    it "returns true when both checksum and alt_text differ" do
      shopify_info.update!(checksum: "different_checksum", alt_text: "Different Alt")
      result = described_class.new.send(:media_changed?, media, shopify_info)
      expect(result).to be true
    end
  end

  describe "#attach_new_media" do
    let(:shopify_product_id) { "gid://shopify/Product/123" }
    let(:product) { create(:product_with_brands) }
    let(:first_media) { create(:media, :for_product, alt: "Image 1") }
    let(:second_media) { create(:media, :for_product, alt: "Image 2") }
    let(:api_client) { instance_spy(Shopify::Api::Client) }

    let(:created_shopify_media) do
      [
        {"id" => "gid://shopify/MediaImage/456", "alt" => "Image 1", "createdAt" => "2024-01-15T10:00:00Z", "updatedAt" => "2024-01-15T10:00:00Z"},
        {"id" => "gid://shopify/MediaImage/457", "alt" => "Image 2", "createdAt" => "2024-01-15T10:01:00Z", "updatedAt" => "2024-01-15T10:01:00Z"}
      ]
    end

    before do
      ActiveStorage::Current.url_options = {host: "example.com"}
      allow(first_media.image.blob.service).to receive(:exist?).with(first_media.image.blob.key).and_return(true)
      allow(second_media.image.blob.service).to receive(:exist?).with(second_media.image.blob.key).and_return(true)
      allow(api_client).to receive(:attach_media).with(shopify_product_id, kind_of(Array)).and_return(created_shopify_media)
    end

    it "builds correct media input array" do
      job = described_class.new
      job.instance_variable_set(:@product, product)
      job.instance_variable_set(:@product_store_id, shopify_product_id)
      job.instance_variable_set(:@api_client, api_client)
      job.instance_variable_set(:@new_media, [first_media, second_media])
      job.send(:attach_new_media)

      expect(api_client).to have_received(:attach_media).with(shopify_product_id, kind_of(Array)) do |_id, media_input|
        expect(media_input.size).to eq(2)
        expect(media_input.first).to include(
          originalSource: kind_of(String),
          alt: "Image 1",
          mediaContentType: "IMAGE"
        )
      end
    end

    it "saves Shopify media IDs to StoreInfo" do
      expect {
        job = described_class.new
        job.instance_variable_set(:@product, product)
        job.instance_variable_set(:@product_store_id, shopify_product_id)
        job.instance_variable_set(:@api_client, api_client)
        job.instance_variable_set(:@new_media, [first_media, second_media])
        job.send(:attach_new_media)
      }.to change { first_media.store_infos.where(store_name: :shopify).count }.by(1)
        .and change { second_media.store_infos.where(store_name: :shopify).count }.by(1)

      expect(first_media.store_infos.find_by(store_name: :shopify).store_id).to eq("gid://shopify/MediaImage/456")
      expect(second_media.store_infos.find_by(store_name: :shopify).store_id).to eq("gid://shopify/MediaImage/457")
    end

    it "saves checksum, alt_text, and timestamps to StoreInfo" do
      job = described_class.new
      job.instance_variable_set(:@product, product)
      job.instance_variable_set(:@product_store_id, shopify_product_id)
      job.instance_variable_set(:@api_client, api_client)
      job.instance_variable_set(:@new_media, [first_media])
      job.send(:attach_new_media)

      store_info = first_media.store_infos.find_by(store_name: :shopify)
      expect(store_info.checksum).to eq(first_media.image.blob.checksum)
      expect(store_info.alt_text).to eq("Image 1")
      expect(store_info.ext_created_at).to be_present
      expect(store_info.ext_updated_at).to be_present
      expect(store_info.push_time).to be_present
    end
  end

  describe "#update_existing_media" do
    let(:product) { create(:product_with_brands) }
    let(:media) { create(:media, :for_product, alt: "Updated Alt") }
    let(:api_client) { instance_spy(Shopify::Api::Client) }

    let(:updated_shopify_files) do
      [
        {"id" => "gid://shopify/MediaImage/789", "alt" => "Updated Alt", "createdAt" => "2024-01-10T10:00:00Z", "updatedAt" => "2024-01-15T11:00:00Z"}
      ]
    end

    before do
      # Create shopify_info after media is created
      create(:store_info, :shopify, storable: media, store_id: "gid://shopify/MediaImage/789", checksum: "old_checksum", alt_text: "Old Alt")
      media.reload # Reload to ensure association is cached

      ActiveStorage::Current.url_options = {host: "example.com"}
      allow(media.image.blob.service).to receive(:exist?).with(media.image.blob.key).and_return(true)
      allow(api_client).to receive(:update_media).with(kind_of(Array)).and_return(updated_shopify_files)
    end

    it "builds correct file updates array" do
      job = described_class.new
      job.instance_variable_set(:@product, product)
      job.instance_variable_set(:@api_client, api_client)
      job.instance_variable_set(:@existing_media, [media])
      job.send(:update_existing_media)

      expect(api_client).to have_received(:update_media).with(kind_of(Array)) do |file_updates|
        expect(file_updates.size).to eq(1)
        expect(file_updates.first).to include(
          id: "gid://shopify/MediaImage/789",
          originalSource: kind_of(String),
          alt: "Updated Alt"
        )
      end
    end

    it "updates store_info with new checksum, alt_text, and timestamps" do
      shopify_info = media.shopify_info

      job = described_class.new
      job.instance_variable_set(:@product, product)
      job.instance_variable_set(:@api_client, api_client)
      job.instance_variable_set(:@existing_media, [media])
      job.send(:update_existing_media)

      shopify_info.reload
      expect(shopify_info.checksum).to eq(media.image.blob.checksum)
      expect(shopify_info.alt_text).to eq("Updated Alt")
      expect(shopify_info.ext_created_at).to eq(Time.zone.parse("2024-01-10T10:00:00Z"))
      expect(shopify_info.ext_updated_at).to eq(Time.zone.parse("2024-01-15T11:00:00Z"))
      expect(shopify_info.push_time).to be_present
    end
  end

  describe "#update_shopify_store_infos" do
    let(:media) { create(:media, :for_product, alt: "New Alt") }
    let(:shopify_info) { create(:store_info, :shopify, storable: media, store_id: "gid://shopify/MediaImage/789") }

    let(:shopify_files) do
      [
        {"id" => "gid://shopify/MediaImage/789", "alt" => "New Alt", "createdAt" => "2024-01-10T10:00:00Z", "updatedAt" => "2024-01-15T11:00:00Z"}
      ]
    end

    before { shopify_info }

    it "updates all existing media with checksum, alt_text, and timestamps" do
      changed_media = [media.reload]

      job = described_class.new
      job.send(:update_shopify_store_infos, changed_media, shopify_files)

      shopify_info.reload
      expect(shopify_info.checksum).to eq(media.image.blob.checksum)
      expect(shopify_info.alt_text).to eq("New Alt")
      expect(shopify_info.ext_created_at).to eq(Time.zone.parse("2024-01-10T10:00:00Z"))
      expect(shopify_info.ext_updated_at).to eq(Time.zone.parse("2024-01-15T11:00:00Z"))
      expect(shopify_info.push_time).to be_within(2.seconds).of(Time.zone.now)
    end

    it "handles missing shopify_files gracefully" do
      changed_media = [media.reload]

      expect {
        job = described_class.new
        job.send(:update_shopify_store_infos, changed_media, [])
      }.not_to raise_error

      shopify_info.reload
      expect(shopify_info.checksum).to eq(media.image.blob.checksum)
      expect(shopify_info.alt_text).to eq("New Alt")
      expect(shopify_info.ext_created_at).to be_nil
      expect(shopify_info.ext_updated_at).to be_nil
    end

    it "matches shopify_file to media by store_id" do
      media2 = create(:media, :for_product, alt: "Another Media")
      shopify_info2 = create(:store_info, :shopify, storable: media2, store_id: "gid://shopify/MediaImage/999")

      shopify_files = [
        {"id" => "gid://shopify/MediaImage/789", "alt" => "New Alt", "createdAt" => "2024-01-10T10:00:00Z", "updatedAt" => "2024-01-15T11:00:00Z"},
        {"id" => "gid://shopify/MediaImage/999", "alt" => "Another Media", "createdAt" => "2024-01-10T10:01:00Z", "updatedAt" => "2024-01-15T11:01:00Z"}
      ]

      changed_media = [media.reload, media2.reload]

      job = described_class.new
      job.send(:update_shopify_store_infos, changed_media, shopify_files)

      shopify_info.reload
      shopify_info2.reload

      expect(shopify_info.ext_created_at).to eq(Time.zone.parse("2024-01-10T10:00:00Z"))
      expect(shopify_info2.ext_created_at).to eq(Time.zone.parse("2024-01-10T10:01:00Z"))
    end
  end

  describe "#save_shopify_media_ids" do
    let(:first_media) { create(:media, :for_product, alt: "Image 1") }
    let(:second_media) { create(:media, :for_product, alt: "Image 2") }
    let(:shopify_media) do
      [
        {"id" => "gid://shopify/MediaImage/456", "alt" => "Image 1", "createdAt" => "2024-01-15T10:00:00Z", "updatedAt" => "2024-01-15T10:00:00Z"},
        {"id" => "gid://shopify/MediaImage/457", "alt" => "Image 2", "createdAt" => "2024-01-15T10:01:00Z", "updatedAt" => "2024-01-15T10:01:00Z"}
      ]
    end

    it "creates StoreInfo records for each media" do
      local_media = [first_media, second_media]

      expect {
        job = described_class.new
        job.send(:save_shopify_media_ids, local_media, shopify_media)
      }.to change { StoreInfo.where(store_name: :shopify).count }.by(2)
    end

    it "pairs local media with Shopify media by index" do
      local_media = [first_media, second_media]

      job = described_class.new
      job.send(:save_shopify_media_ids, local_media, shopify_media)

      expect(first_media.store_infos.find_by(store_name: :shopify).store_id).to eq("gid://shopify/MediaImage/456")
      expect(second_media.store_infos.find_by(store_name: :shopify).store_id).to eq("gid://shopify/MediaImage/457")
    end

    it "sets store_name to :shopify" do
      local_media = [first_media]

      job = described_class.new
      job.send(:save_shopify_media_ids, local_media, shopify_media)

      expect(first_media.store_infos.last.store_name).to eq("shopify")
    end

    it "saves checksum and alt_text" do
      local_media = [first_media]

      job = described_class.new
      job.send(:save_shopify_media_ids, local_media, shopify_media)

      store_info = first_media.store_infos.find_by(store_name: :shopify)
      expect(store_info.checksum).to eq(first_media.image.blob.checksum)
      expect(store_info.alt_text).to eq("Image 1")
    end

    it "saves ext_created_at and ext_updated_at timestamps" do
      local_media = [first_media]

      job = described_class.new
      job.send(:save_shopify_media_ids, local_media, shopify_media)

      store_info = first_media.store_infos.find_by(store_name: :shopify)
      expect(store_info.ext_created_at).to eq(Time.zone.parse("2024-01-15T10:00:00Z"))
      expect(store_info.ext_updated_at).to eq(Time.zone.parse("2024-01-15T10:00:00Z"))
    end

    it "saves push_time timestamp" do
      local_media = [first_media]

      freeze_time do
        job = described_class.new
        job.send(:save_shopify_media_ids, local_media, shopify_media)

        store_info = first_media.store_infos.find_by(store_name: :shopify)
        expect(store_info.push_time).to be_within(2.seconds).of(Time.zone.now)
      end
    end
  end

  describe "#reorder_media_on_shopify" do
    let(:shopify_product_id) { "gid://shopify/Product/123" }
    let(:product) { create(:product_with_brands) }
    let(:api_client) { instance_spy(Shopify::Api::Client) }
    let(:first_media) { create(:media, :for_product, alt: "Image 1", position: 0) }
    let(:second_media) { create(:media, :for_product, alt: "Image 2", position: 1) }
    let(:third_media) { create(:media, :for_product, alt: "Image 3", position: 2) }

    let(:shopify_product_response) do
      {
        "id" => shopify_product_id,
        "title" => "Test Product",
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
      product.media << [first_media, second_media, third_media]
      allow(api_client).to receive(:fetch_product).with(shopify_product_id).and_return(shopify_product_response)
    end

    it "fetches Shopify product to compare positions" do
      first_media.store_infos.create!(store_name: :shopify, store_id: "gid://shopify/MediaImage/456")

      job = described_class.new
      job.instance_variable_set(:@product, product)
      job.instance_variable_set(:@product_store_id, shopify_product_id)
      job.instance_variable_set(:@api_client, api_client)
      job.send(:reorder_media_on_shopify)

      expect(api_client).to have_received(:fetch_product).with(shopify_product_id)
    end

    it "only sends moves for media whose positions have changed" do
      first_media.store_infos.create!(store_name: :shopify, store_id: "gid://shopify/MediaImage/456")
      second_media.store_infos.create!(store_name: :shopify, store_id: "gid://shopify/MediaImage/458")
      third_media.store_infos.create!(store_name: :shopify, store_id: "gid://shopify/MediaImage/457")

      # Shopify order: 456, 457, 458 (indices 0, 1, 2)
      # Local order: 456 at 0, 458 at 1 (was at 2), 457 at 2 (was at 1)
      # Only 458 and 457 have changed positions

      job = described_class.new
      job.instance_variable_set(:@product, product)
      job.instance_variable_set(:@product_store_id, shopify_product_id)
      job.instance_variable_set(:@api_client, api_client)
      job.send(:reorder_media_on_shopify)

      expect(api_client).to have_received(:reorder_media).with(shopify_product_id, [
        {id: "gid://shopify/MediaImage/458", newPosition: "1"},
        {id: "gid://shopify/MediaImage/457", newPosition: "2"}
      ])
    end

    it "uses string-encoded integer positions as required by GraphQL" do
      # Shopify order: 456, 457, 458 (indices 0, 1, 2)
      # Local order swapped: 458, 456, 457 (positions 0, 1, 2)
      first_media.store_infos.create!(store_name: :shopify, store_id: "gid://shopify/MediaImage/458")
      second_media.store_infos.create!(store_name: :shopify, store_id: "gid://shopify/MediaImage/456")
      third_media.store_infos.create!(store_name: :shopify, store_id: "gid://shopify/MediaImage/457")

      job = described_class.new
      job.instance_variable_set(:@product, product)
      job.instance_variable_set(:@product_store_id, shopify_product_id)
      job.instance_variable_set(:@api_client, api_client)
      job.send(:reorder_media_on_shopify)

      expect(api_client).to have_received(:reorder_media).with(shopify_product_id, kind_of(Array)) do |_id, moves|
        moves.each do |move|
          expect(move[:newPosition]).to be_a(String)
          expect(move[:newPosition]).to match(/^\d+$/)
        end
      end
    end

    it "returns early if no media has Shopify IDs" do
      job = described_class.new
      job.instance_variable_set(:@product, product)
      job.instance_variable_set(:@product_store_id, shopify_product_id)
      job.instance_variable_set(:@api_client, api_client)
      job.send(:reorder_media_on_shopify)

      expect(api_client).not_to have_received(:reorder_media)
    end

    it "only includes media that have been synced to Shopify" do
      first_media.store_infos.create!(store_name: :shopify, store_id: "gid://shopify/MediaImage/456")
      # second_media not synced
      third_media.store_infos.create!(store_name: :shopify, store_id: "gid://shopify/MediaImage/458")

      job = described_class.new
      job.instance_variable_set(:@product, product)
      job.instance_variable_set(:@product_store_id, shopify_product_id)
      job.instance_variable_set(:@api_client, api_client)
      job.send(:reorder_media_on_shopify)

      # Only 456 and 458 synced, both at correct positions (0 and 2)
      # Positions match Shopify, so reorder_media is not called
      expect(api_client).not_to have_received(:reorder_media)
    end

    it "handles positions correctly when all media are in order" do
      first_media.store_infos.create!(store_name: :shopify, store_id: "gid://shopify/MediaImage/456")
      second_media.store_infos.create!(store_name: :shopify, store_id: "gid://shopify/MediaImage/457")
      third_media.store_infos.create!(store_name: :shopify, store_id: "gid://shopify/MediaImage/458")

      job = described_class.new
      job.instance_variable_set(:@product, product)
      job.instance_variable_set(:@product_store_id, shopify_product_id)
      job.instance_variable_set(:@api_client, api_client)
      job.send(:reorder_media_on_shopify)

      # All positions match Shopify, no moves needed, so reorder_media is not called
      expect(api_client).not_to have_received(:reorder_media)
    end

    it "handles media reordering correctly" do
      # Simulate media being reordered locally: second_media moved to position 0
      second_media.update!(position: 0)
      first_media.update!(position: 1)
      # third_media stays at position 2

      first_media.store_infos.create!(store_name: :shopify, store_id: "gid://shopify/MediaImage/456")
      second_media.store_infos.create!(store_name: :shopify, store_id: "gid://shopify/MediaImage/457")
      third_media.store_infos.create!(store_name: :shopify, store_id: "gid://shopify/MediaImage/458")

      job = described_class.new
      job.instance_variable_set(:@product, product)
      job.instance_variable_set(:@product_store_id, shopify_product_id)
      job.instance_variable_set(:@api_client, api_client)
      job.send(:reorder_media_on_shopify)

      # Local: 457 at 0, 456 at 1, 458 at 2
      # Shopify: 456 at 0, 457 at 1, 458 at 2
      # Only 457 and 456 need to move
      expect(api_client).to have_received(:reorder_media).with(shopify_product_id, [
        {id: "gid://shopify/MediaImage/457", newPosition: "0"},
        {id: "gid://shopify/MediaImage/456", newPosition: "1"}
      ])
    end
  end

  describe "#wait_until_file_is_available" do
    let(:media) { create(:media, :for_product) }
    let(:job) { described_class.new }

    it "returns immediately when file is available" do
      allow(media.image.blob.service).to receive(:exist?).with(media.image.blob.key).and_return(true)

      expect { job.send(:wait_until_file_is_available, media.image.blob) }.not_to raise_error
    end

    it "polls until file becomes available" do
      # File becomes available after 3 checks
      allow(media.image.blob.service).to receive(:exist?).with(media.image.blob.key).and_return(false, false, true)
      allow(job).to receive(:sleep)

      expect { job.send(:wait_until_file_is_available, media.image.blob, 10, 0.1) }.not_to raise_error

      expect(media.image.blob.service).to have_received(:exist?).with(media.image.blob.key).exactly(3).times
      expect(job).to have_received(:sleep).twice
    end

    it "raises error after timeout" do
      allow(media.image.blob.service).to receive(:exist?).with(media.image.blob.key).and_return(false)
      allow(job).to receive(:sleep)

      expect {
        job.send(:wait_until_file_is_available, media.image.blob, 1, 0.1)
      }.to raise_error(RuntimeError, /File was not uploaded to R2/)
    end
  end
end
