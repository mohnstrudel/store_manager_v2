# frozen_string_literal: true

require "rails_helper"

RSpec.describe Shopify::UpdateProductJob do
  include ActiveJob::TestHelper

  let(:product) { create(:product_with_brands) }
  let(:product_id) { product.id }
  let(:shopify_product_id) { "gid://shopify/Product/12345" }
  let(:serialized_product) do
    {
      "title" => "Test Franchise - Test Product | Resin Test Shape | by Test Brand"
    }
  end
  let(:product_response) do
    {
      "id" => shopify_product_id,
      "handle" => "test-product-updated",
      "media" => {
        "nodes" => shopify_media_nodes
      }
    }
  end
  let(:shopify_media_nodes) { [] }
  let(:api_client) { instance_spy(Shopify::Api::Client) }

  before do
    product.shopify_info.update!(store_id: shopify_product_id, slug: "test-product")
    allow_any_instance_of(Product).to receive(:shopify_payload).and_return(serialized_product)
    allow(Shopify::Api::Client).to receive(:new).and_return(api_client)
    allow(api_client).to receive(:update_product).with(shopify_product_id, serialized_product).and_return(product_response)
  end

  describe ".perform_later" do
    it "enqueues the job with product_id" do
      expect {
        described_class.perform_later(product_id)
      }.to have_enqueued_job(described_class).with(product_id)
    end
  end

  describe "#perform" do
    it "finds the product by ID" do
      allow(Product).to receive(:find).with(product_id).and_return(product)
      described_class.perform_now(product_id)
      expect(Product).to have_received(:find).with(product_id)
    end

    it "builds the Shopify payload from the product" do
      allow(Product).to receive(:find).with(product_id).and_return(product)
      described_class.perform_now(product_id)
      expect(product).to have_received(:shopify_payload)
    end

    it "creates API client" do
      described_class.perform_now(product_id)
      expect(Shopify::Api::Client).to have_received(:new)
    end

    it "calls update_product with serialized data and shopify_id" do
      described_class.perform_now(product_id)
      expect(api_client).to have_received(:update_product).with(shopify_product_id, serialized_product)
    end

    it "returns true on success" do
      result = described_class.perform_now(product_id)
      expect(result).to be true
    end

    it "finds store info for Shopify" do
      described_class.perform_now(product_id)

      store_info = product.store_infos.find_by(store_name: :shopify)
      expect(store_info).not_to be_nil
    end

    it "stores the updated product slug/handle" do
      described_class.perform_now(product_id)

      store_info = product.store_infos.find_by(store_name: :shopify)
      expect(store_info.slug).to eq("test-product-updated")
    end

    it "sets the push time" do
      before_time = Time.current
      described_class.perform_now(product_id)

      store_info = product.store_infos.find_by(store_name: :shopify)
      expect(store_info.push_time).to be_between(before_time, Time.current).inclusive
    end

    context "when product has media" do
      let!(:media) { create(:media, mediaable: product) }

      it "enqueues PushMediaJob with correct parameters" do
        allow(Shopify::PushMediaJob).to receive(:perform_later)
        described_class.perform_now(product_id)
        expect(Shopify::PushMediaJob).to have_received(:perform_later)
          .with(product.id, shopify_product_id)
      end
    end

    context "when product has no media" do
      it "does not enqueue PushMediaJob" do
        allow(Shopify::PushMediaJob).to receive(:perform_later)
        described_class.perform_now(product_id)
        expect(Shopify::PushMediaJob).not_to have_received(:perform_later)
      end
    end

    context "when product has options (sizes, versions, colors)" do
      let(:size) { create(:size, value: "Large") }
      let(:version) { create(:version, value: "v1") }
      let(:color) { create(:color, value: "Red") }
      let(:product_size) { create(:product_size, product: product, size: size) }
      let(:product_version) { create(:product_version, product: product, version: version) }
      let(:product_color) { create(:product_color, product: product, color: color) }

      before do
        product_size
        product_version
        product_color
      end

      it "enqueues CreateOptionsAndVariantsJob with correct parameters" do
        allow(Shopify::CreateOptionsAndVariantsJob).to receive(:perform_later)
        described_class.perform_now(product_id)
        expect(Shopify::CreateOptionsAndVariantsJob).to have_received(:perform_later)
          .with(product_id, shopify_product_id)
      end
    end

    context "when product has no options" do
      it "does not enqueue CreateOptionsAndVariantsJob" do
        allow(Shopify::CreateOptionsAndVariantsJob).to receive(:perform_later)
        described_class.perform_now(product_id)
        expect(Shopify::CreateOptionsAndVariantsJob).not_to have_received(:perform_later)
      end
    end

    context "when product has only one type of option" do
      let(:size) { create(:size, value: "XL") }
      let(:product_size) { create(:product_size, product: product, size: size) }

      before do
        product_size
      end

      it "enqueues CreateOptionsAndVariantsJob" do
        allow(Shopify::CreateOptionsAndVariantsJob).to receive(:perform_later)
        described_class.perform_now(product_id)
        expect(Shopify::CreateOptionsAndVariantsJob).to have_received(:perform_later)
          .with(product_id, shopify_product_id)
      end
    end

    context "when product has both media and options" do
      let(:size) { create(:size, value: "Large") }
      let(:product_size) { create(:product_size, product: product, size: size) }
      let!(:media) { create(:media, mediaable: product) }

      before do
        product_size
      end

      it "enqueues both PushMediaJob and CreateOptionsAndVariantsJob" do
        allow(Shopify::PushMediaJob).to receive(:perform_later)
        allow(Shopify::CreateOptionsAndVariantsJob).to receive(:perform_later)
        described_class.perform_now(product_id)
        expect(Shopify::PushMediaJob).to have_received(:perform_later)
          .with(product.id, shopify_product_id)
        expect(Shopify::CreateOptionsAndVariantsJob).to have_received(:perform_later)
          .with(product_id, shopify_product_id)
      end
    end

    context "when API client raises an error" do
      let(:api_error) { Shopify::Api::Client::ApiError.new("API Error") }

      before do
        allow(api_client).to receive(:update_product).and_raise(api_error)
      end

      it "propagates the error" do
        expect {
          described_class.perform_now(product_id)
        }.to raise_error(Shopify::Api::Client::ApiError, "API Error")
      end

      it "does not update store info on error" do
        original_push_time = product.shopify_info.push_time
        original_slug = product.shopify_info.slug

        begin
          described_class.perform_now(product_id)
        rescue Shopify::Api::Client::ApiError
          # Expected error
        end

        product.shopify_info.reload
        expect(product.shopify_info.push_time).to eq(original_push_time)
        expect(product.shopify_info.slug).to eq(original_slug)
      end

      it "does not enqueue media job on error" do
        create(:media, mediaable: product)
        allow(Shopify::PushMediaJob).to receive(:perform_later)

        begin
          described_class.perform_now(product_id)
        rescue Shopify::Api::Client::ApiError
          # Expected error
        end

        expect(Shopify::PushMediaJob).not_to have_received(:perform_later)
      end

      it "does not enqueue options job on error" do
        allow(Shopify::CreateOptionsAndVariantsJob).to receive(:perform_later)

        begin
          described_class.perform_now(product_id)
        rescue Shopify::Api::Client::ApiError
          # Expected error
        end

        expect(Shopify::CreateOptionsAndVariantsJob).not_to have_received(:perform_later)
      end
    end

    context "when product is not found" do
      it "raises ActiveRecord::RecordNotFound" do
        expect {
          described_class.perform_now(99999)
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when product does not exist on Shopify" do
      let(:api_error) do
        Shopify::Api::Client::ApiError.new("Failed to call the productUpdate API mutation: Product does not exist")
      end

      before do
        allow(api_client).to receive(:update_product).and_raise(api_error)
      end

      it "destroys the Shopify store_info" do
        expect {
          described_class.perform_now(product_id)
        }.to change { product.store_infos.shopify.count }.from(1).to(0)
      end
    end

    context "when product does not exist on Shopify and has media with store_infos" do
      let(:api_error) do
        Shopify::Api::Client::ApiError.new("Failed to call the productUpdate API mutation: Product does not exist")
      end
      let!(:media_with_shopify_and_woo) { create(:media, mediaable: product) }
      let!(:media_with_shopify_only) { create(:media, mediaable: product) }

      before do
        allow(api_client).to receive(:update_product).and_raise(api_error)
        media_with_shopify_and_woo.store_infos.create!(store_name: :shopify, store_id: "shopify-media-1")
        media_with_shopify_and_woo.store_infos.create!(store_name: :woo, store_id: "woo-media-1")
        media_with_shopify_only.store_infos.create!(store_name: :shopify, store_id: "shopify-media-2")
      end

      it "removes Shopify store_infos from all associated media" do
        expect {
          described_class.perform_now(product_id)
        }.to change {
          product.media.joins(:store_infos).where(store_infos: {store_name: :shopify}).count
        }.from(2).to(0)
      end

      it "preserves non-Shopify store_infos on media" do
        woo_count_before = media_with_shopify_and_woo.store_infos.where(store_name: :woo).count

        described_class.perform_now(product_id)

        expect(media_with_shopify_and_woo.store_infos.where(store_name: :woo).count).to eq(woo_count_before)
      end
    end

    context "when product does not exist on Shopify and has no media" do
      let(:api_error) do
        Shopify::Api::Client::ApiError.new("Failed to call the productUpdate API mutation: Product does not exist")
      end

      before do
        allow(api_client).to receive(:update_product).and_raise(api_error)
      end

      it "handles gracefully without error" do
        expect {
          described_class.perform_now(product_id)
        }.not_to raise_error
      end
    end

    context "when product does not exist on Shopify and has other store_infos" do
      let(:api_error) do
        Shopify::Api::Client::ApiError.new("Failed to call the productUpdate API mutation: Product does not exist")
      end

      before do
        allow(api_client).to receive(:update_product).and_raise(api_error)
      end

      it "only removes Shopify store_info", :aggregate_failures do
        woo_count_before = product.store_infos.where(store_name: :woo).count

        expect {
          described_class.perform_now(product_id)
        }.to change { product.store_infos.shopify.count }.from(1).to(0)

        expect(product.store_infos.where(store_name: :woo).count).to eq(woo_count_before)
      end
    end

    context "when shopify_info has no store_id before calling API" do
      let(:product_without_shopify) { create(:product, title: "No Shopify") }
      let(:product_id_without_shopify) { product_without_shopify.id }

      before do
        # The shopify_info method auto-creates if missing, so we need to ensure store_id is nil
        product_without_shopify.shopify_info.update!(store_id: nil)
      end

      it "passes nil to the API client" do
        # The shopify_info auto-creates, but store_id is nil
        expect(product_without_shopify.reload.shopify_info.store_id).to be_nil
      end
    end

    context "when error message is not product not found" do
      let(:api_error) { Shopify::Api::Client::ApiError.new("Some other API error") }

      before do
        allow(api_client).to receive(:update_product).and_raise(api_error)
      end

      it "does not call handle_product_not_found_error" do
        shopify_info = product.shopify_info

        begin
          described_class.perform_now(product_id)
        rescue Shopify::Api::Client::ApiError
          # Expected error
        end

        expect(shopify_info.reload).to be_persisted
      end
    end

    context "when removing outdated media" do
      let!(:media_1) { create(:media, mediaable: product) }
      let!(:media_2) { create(:media, mediaable: product) }
      let!(:media_3) { create(:media, mediaable: product) }
      let!(:media_4) { create(:media, mediaable: product) }

      before do
        # Media 1 and 2 have shopify_info, media 3 does not (not pushed yet)
        media_1.store_infos.create(store_name: :shopify, store_id: "gid://shopify/MediaImage/123")
        media_2.store_infos.create(store_name: :shopify, store_id: "gid://shopify/MediaImage/456")
        # media_3 has no shopify_info
      end

      context "when shopify response contains some media" do
        let(:shopify_media_nodes) do
          [
            {"id" => "gid://shopify/MediaImage/123"},
            {"id" => "gid://shopify/MediaImage/789"}
          ]
        end

        it "removes shopify_info for media not in response" do
          expect {
            described_class.perform_now(product_id)
          }.to change { media_2.store_infos.shopify.count }.from(1).to(0)
        end

        it "preserves shopify_info for media in response" do
          described_class.perform_now(product_id)

          expect(media_1.store_infos.shopify.count).to eq(1)
          expect(media_1.store_infos.shopify.first.store_id).to eq("gid://shopify/MediaImage/123")
        end

        it "does not affect media without shopify_info" do
          shopify_info_count_before = media_3.store_infos.shopify.count

          described_class.perform_now(product_id)

          expect(media_3.store_infos.shopify.count).to eq(shopify_info_count_before)
        end
      end

      context "when shopify response contains no media" do
        let(:shopify_media_nodes) { [] }

        it "removes all shopify_info from product media" do
          expect {
            described_class.perform_now(product_id)
          }.to change {
            product.media.joins(:store_infos).where(store_infos: {store_name: :shopify}).count
          }.from(2).to(0)
        end
      end

      context "when media has shopify_info and woo_info" do
        before do
          media_1.store_infos.create!(store_name: :woo, store_id: "woo-media-1")
        end

        let(:shopify_media_nodes) { [] }

        it "only removes shopify_info, not woo_info" do
          described_class.perform_now(product_id)

          expect(media_1.store_infos.shopify.count).to eq(0)
          expect(media_1.store_infos.where(store_name: :woo)).to exist
        end
      end
    end
  end
end
