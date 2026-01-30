# frozen_string_literal: true

require "rails_helper"

RSpec.describe Shopify::PullProductJob do
  include ActiveJob::TestHelper

  let(:job) { described_class.new }
  let(:product_id) { "gid://shopify/Product/12345" }
  let(:api_response) do
    {
      "id" => product_id,
      "title" => "Test Product",
      "handle" => "test-product"
    }
  end
  let(:parsed_product) do
    {
      shopify_id: product_id,
      title: "Test Product",
      franchise: "Test Franchise",
      shape: "Statue"
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
    let(:api_client) { instance_double(Shopify::ApiClient) }
    let(:parser) { instance_double(Shopify::ProductParser, parse: parsed_product) }
    let(:creator) { instance_double(Shopify::ProductCreator, update_or_create!: nil) }

    before do
      allow(Shopify::ApiClient).to receive(:new).and_return(api_client)
      allow(api_client).to receive(:pull_product).with(product_id).and_return(api_response)
      allow(Shopify::ProductParser).to receive(:new).with(api_item: api_response).and_return(parser)
      allow(Shopify::ProductCreator).to receive(:new).with(parsed_item: parsed_product).and_return(creator)
    end

    context "with valid product_id and valid response" do
      it "creates API client" do
        job.perform(product_id)
        expect(Shopify::ApiClient).to have_received(:new)
      end

      it "pulls product from Shopify" do
        job.perform(product_id)
        expect(api_client).to have_received(:pull_product).with(product_id)
      end

      it "parses the response" do
        job.perform(product_id)
        expect(Shopify::ProductParser).to have_received(:new).with(api_item: api_response)
        expect(parser).to have_received(:parse)
      end

      it "creates or updates product" do
        job.perform(product_id)
        expect(Shopify::ProductCreator).to have_received(:new).with(parsed_item: parsed_product)
        expect(creator).to have_received(:update_or_create!)
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
        allow(api_client).to receive(:pull_product).and_raise(api_error)
      end

      it "propagates the error" do
        expect {
          job.perform(product_id)
        }.to raise_error(ShopifyAPI::Errors::HttpResponseError)
      end
    end

    context "when product creator fails" do
      before do
        allow(creator).to receive(:update_or_create!).and_raise(
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
        allow(api_client).to receive(:pull_product).with(product_id).and_return(nil)
      end

      it "returns early without calling parser or creator" do
        job.perform(product_id)
        expect(Shopify::ProductParser).not_to have_received(:new)
        expect(Shopify::ProductCreator).not_to have_received(:new)
      end

      context "when store_info exists for the product_id" do
        let!(:store_info) do
          product.store_infos.find_by(store_name: "shopify").tap do |si|
            si.update!(store_id: product_id)
          end
        end

        let(:media1) { create(:media, :for_product, mediaable: product) }
        let(:media2) { create(:media, :for_product, mediaable: product) }
        let!(:media1_shopify_info) { create(:store_info, storable: media1, store_name: "shopify") }
        let!(:media2_shopify_info) { create(:store_info, storable: media2, store_name: "shopify") }
        let!(:media2_woo_info) { create(:store_info, :woo, storable: media2) }

        it "finds and destroys the product's shopify store_info" do
          expect {
            job.perform(product_id)
          }.to change(StoreInfo, :count).by(-3) # product shopify + media1 shopify + media2 shopify

          expect(StoreInfo.find_by(id: store_info.id)).to be_nil
        end

        it "removes shopify store_infos from all associated media" do
          job.perform(product_id)

          expect(media1.store_infos.where(store_name: "shopify")).to be_empty
          expect(media2.store_infos.where(store_name: "shopify")).to be_empty
        end

        it "preserves woo store_infos on media" do
          job.perform(product_id)

          expect(media2.store_infos.where(store_name: "woo")).to exist
        end
      end

      context "when no store_info exists for the product_id" do
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

  describe "#handle_product_not_found" do
    let(:product) { create(:product) }

    context "when store_info exists" do
      let!(:store_info) do
        product.store_infos.find_by(store_name: "shopify").tap do |si|
          si.update!(store_id: product_id)
        end
      end

      let(:media1) { create(:media, :for_product, mediaable: product) }
      let(:media2) { create(:media, :for_product, mediaable: product) }
      let!(:media1_shopify_info) { create(:store_info, storable: media1, store_name: "shopify") }
      let!(:media2_shopify_info) { create(:store_info, storable: media2, store_name: "shopify") }
      let!(:media2_woo_info) { create(:store_info, :woo, storable: media2) }

      it "finds the store_info by shopify store_name and store_id" do
        job.send(:handle_product_not_found, product_id)
        expect(StoreInfo.find_by(id: store_info.id)).to be_nil
      end

      it "destroys the store_info record" do
        expect {
          job.send(:handle_product_not_found, product_id)
        }.to change(StoreInfo, :count).by(-3)
      end

      it "removes shopify store_infos from all associated media" do
        job.send(:handle_product_not_found, product_id)

        expect(media1.store_infos.where(store_name: "shopify")).to be_empty
        expect(media2.store_infos.where(store_name: "shopify")).to be_empty
      end

      it "preserves woo store_infos on media" do
        job.send(:handle_product_not_found, product_id)

        expect(media2.store_infos.where(store_name: "woo")).to exist
      end
    end

    context "when no store_info exists" do
      before do
        product.store_infos.where(store_name: "shopify").destroy_all
      end

      it "returns nil" do
        result = job.send(:handle_product_not_found, "nonexistent_id")
        expect(result).to be_nil
      end
    end
  end
end
