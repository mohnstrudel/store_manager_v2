# frozen_string_literal: true

require "rails_helper"

RSpec.describe Shopify::PullProductJob do
  include ActiveJob::TestHelper

  let(:job) { described_class.new }
  let(:product_id) { "gid://shopify/Product/12345" }
  let(:api_response) do
    {
      "id" => product_id,
      "title" => "Elden Ring - Malenia | 1:4 | Resin Statue | by Prime 1 Studio",
      "handle" => "test-product",
      "createdAt" => "2024-01-01T00:00:00Z",
      "updatedAt" => "2024-01-01T00:00:00Z",
      "variants" => {
        "edges" => [
          {
            "node" => {
              "id" => "gid://shopify/ProductVariant/1",
              "title" => "Regular",
              "sku" => "TEST-SKU-001",
              "selectedOptions" => []
            }
          }
        ]
      },
      "media" => {
        "nodes" => [
          {
            "id" => "gid://shopify/MediaImage/1",
            "alt" => "Test Image",
            "image" => {"url" => "https://example.com/image.jpg"},
            "createdAt" => "2024-01-01T00:00:00Z",
            "updatedAt" => "2024-01-01T00:00:00Z"
          }
        ]
      }
    }
  end
  let(:parsed_product) do
    {
      shopify_id: product_id,
      title: "Malenia",
      franchise: "Elden Ring",
      shape: "Statue",
      brand: "Prime 1 Studio",
      size: "1:4",
      sku: "TEST-SKU-001",
      store_link: "test-product",
      store_info: {
        ext_created_at: "2024-01-01T00:00:00Z",
        ext_updated_at: "2024-01-01T00:00:00Z"
      },
      editions: [
        {
          id: "gid://shopify/ProductVariant/1",
          title: "Regular",
          sku: "TEST-SKU-001",
          options: []
        }
      ],
      media: [
        {
          id: "gid://shopify/MediaImage/1",
          alt: "Test Image",
          url: "https://example.com/image.jpg",
          position: 0,
          store_info: {
            ext_created_at: "2024-01-01T00:00:00Z",
            ext_updated_at: "2024-01-01T00:00:00Z"
          }
        }
      ]
    }
  end

  describe ".queue_as" do
    it "enqueues on the default queue" do
      expect {
        described_class.perform_later(product_id)
      }.to have_enqueued_job(described_class).on_queue("default")
    end
  end

  describe ".perform_later" do
    it "enqueues the job with product_id" do
      expect {
        described_class.perform_later(product_id)
      }.to have_enqueued_job(described_class).with(product_id)
    end
  end

  describe "#perform" do
    let(:api_client) { instance_double(Shopify::Api::Client) }

    before do
      allow(Shopify::Api::Client).to receive(:new).and_return(api_client)
      allow(api_client).to receive(:fetch_product).with(product_id).and_return(api_response)
      allow(Product::Shopify::Parser).to receive(:parse).with(api_response).and_return(parsed_product)
      allow(Product::Shopify::Importer).to receive(:import!).with(parsed_product).and_return(instance_double(Product))
    end

    context "with valid product_id and valid response" do
      it "creates API client" do
        job.perform(product_id)
        expect(Shopify::Api::Client).to have_received(:new)
      end

      it "pulls product from Shopify" do
        job.perform(product_id)
        expect(api_client).to have_received(:fetch_product).with(product_id)
      end

      it "parses the response" do
        job.perform(product_id)
        expect(Product::Shopify::Parser).to have_received(:parse).with(api_response)
      end

      it "creates or updates product" do
        job.perform(product_id)
        expect(Product::Shopify::Importer).to have_received(:import!).with(parsed_product)
      end
    end

    context "when API client fails" do
      let(:http_response) do
        ShopifyAPI::Clients::HttpResponse.new(
          code: 500,
          headers: {},
          body: "Internal server error"
        )
      end
      let(:api_error) do
        ShopifyAPI::Errors::HttpResponseError.new(
          response: http_response
        )
      end

      before do
        allow(api_client).to receive(:fetch_product).and_raise(api_error)
      end

      it "propagates the error" do
        expect {
          job.perform(product_id)
        }.to raise_error(ShopifyAPI::Errors::HttpResponseError)
      end
    end

    context "when importer fails" do
      before do
        allow(Product::Shopify::Importer).to receive(:import!).and_raise(
          ActiveRecord::RecordInvalid.new(Product.new)
        )
      end

      it "propagates the error" do
        expect {
          job.perform(product_id)
        }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context "when response is blank" do
      let(:product) { create(:product) }

      before do
        allow(api_client).to receive(:fetch_product).with(product_id).and_return(nil)
      end

      it "returns early without calling parser or importer" do # rubocop:todo RSpec/MultipleExpectations
        job.perform(product_id)
        expect(Product::Shopify::Parser).not_to have_received(:parse)
        expect(Product::Shopify::Importer).not_to have_received(:import!)
      end

      context "when store_info exists for the product_id" do # rubocop:todo RSpec/NestedGroups
        let!(:store_info) do
          product.store_infos.find_by(store_name: "shopify").tap do |si|
            si.update!(store_id: product_id)
          end
        end

        let(:first_media) { create(:media, :for_product, mediaable: product) }
        let(:second_media) { create(:media, :for_product, mediaable: product) }
        let!(:first_media_shopify_info) { create(:store_info, storable: first_media, store_name: "shopify") } # rubocop:todo RSpec/LetSetup
        let!(:second_media_shopify_info) { create(:store_info, storable: second_media, store_name: "shopify") } # rubocop:todo RSpec/LetSetup
        let!(:second_media_woo_info) { create(:store_info, :woo, storable: second_media) } # rubocop:todo RSpec/LetSetup

        it "finds and destroys the product's shopify store_info" do # rubocop:todo RSpec/MultipleExpectations
          expect {
            job.perform(product_id)
          }.to change(StoreInfo, :count).by(-3) # product shopify + first_media shopify + second_media shopify

          expect(StoreInfo.find_by(id: store_info.id)).to be_nil
        end

        it "removes shopify store_infos from all associated media" do # rubocop:todo RSpec/MultipleExpectations
          job.perform(product_id)

          expect(first_media.store_infos.where(store_name: "shopify")).to be_empty
          expect(second_media.store_infos.where(store_name: "shopify")).to be_empty
        end

        it "preserves woo store_infos on media" do
          job.perform(product_id)

          expect(second_media.store_infos.where(store_name: "woo")).to exist
        end
      end

      context "when no store_info exists for the product_id" do # rubocop:todo RSpec/NestedGroups
        before do
          product.store_infos.where(store_name: "shopify").destroy_all
        end

        it "returns gracefully" do
          expect {
            job.perform(product_id)
          }.not_to raise_error
        end
      end
    end
  end

end
