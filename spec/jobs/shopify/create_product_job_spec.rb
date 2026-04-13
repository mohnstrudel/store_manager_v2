# frozen_string_literal: true

require "rails_helper"

RSpec.describe Shopify::CreateProductJob do
  describe "#perform" do
    let(:product) { create(:product_with_brands) }
    let(:product_id) { product.id }
    let(:serialized_product) do
      {
        "title" => "Test Franchise - Test Product | Resin Test Shape | by Test Brand"
      }
    end
    let(:api_client) { instance_spy(Shopify::Api::Client) }
    let(:product_response) do
      {
        "id" => "gid://shopify/Product/12345",
        "handle" => "test-product"
      }
    end

    before do
      allow(Product).to receive(:find).and_call_original
      allow(Product).to receive(:find).with(product_id).and_return(product)
      allow(product).to receive(:shopify_payload).and_return(serialized_product)
      allow(Shopify::Api::Client).to receive(:new).and_return(api_client)
      allow(api_client).to receive(:create_product).with(serialized_product).and_return(product_response)
    end

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

    it "calls create_product with serialized data" do
      described_class.perform_now(product_id)
      expect(api_client).to have_received(:create_product).with(serialized_product)
    end

    it "updates or creates Shopify store info in the domain", :aggregate_failures do
      allow(product).to receive(:link_shopify_info!).and_call_original
      allow(product).to receive(:mark_shopify_pushed!).and_call_original

      described_class.perform_now(product_id)

      expect(product).to have_received(:link_shopify_info!).with(
        store_id: "gid://shopify/Product/12345",
        slug: "test-product"
      )
      expect(product).to have_received(:mark_shopify_pushed!)
    end

    it "returns true on success" do
      result = described_class.perform_now(product_id)
      expect(result).to be true
    end

    it "finds or initializes store info for Shopify" do
      described_class.perform_now(product_id)

      store_info = product.store_infos.find_by(store_name: :shopify)
      expect(store_info).not_to be_nil
    end

    it "stores the Shopify product ID" do
      described_class.perform_now(product_id)

      store_info = product.store_infos.find_by(store_name: :shopify)
      expect(store_info.store_id).to eq("gid://shopify/Product/12345")
    end

    it "stores the product slug/handle" do
      described_class.perform_now(product_id)

      store_info = product.store_infos.find_by(store_name: :shopify)
      expect(store_info.slug).to eq("test-product")
    end

    it "sets the push time" do
      before_time = Time.current
      described_class.perform_now(product_id)

      store_info = product.store_infos.find_by(store_name: :shopify)
      expect(store_info.push_time).to be_between(before_time, Time.current).inclusive
    end

    context "when serialized product is blank" do
      before { allow(product).to receive(:shopify_payload).and_return(nil) }

      it "does not create API client or call create_product" do
        described_class.perform_now(product_id)
        expect(Shopify::Api::Client).not_to have_received(:new)
      end

      it "does not update store info", :aggregate_failures do
        allow(product).to receive(:link_shopify_info!)
        allow(product).to receive(:mark_shopify_pushed!)
        described_class.perform_now(product_id)
        expect(product).not_to have_received(:link_shopify_info!)
        expect(product).not_to have_received(:mark_shopify_pushed!)
      end

      it "does not enqueue options job" do
        allow(Shopify::CreateOptionsAndVariantsJob).to receive(:perform_later)
        described_class.perform_now(product_id)
        expect(Shopify::CreateOptionsAndVariantsJob).not_to have_received(:perform_later)
      end
    end

    context "when store info already exists" do
      let!(:existing_store_info) { product.shopify_info }

      it "updates existing store info with product ID" do
        described_class.perform_now(product_id)

        existing_store_info.reload
        expect(existing_store_info.store_id).to eq("gid://shopify/Product/12345")
      end

      it "updates existing store info with slug" do
        described_class.perform_now(product_id)

        existing_store_info.reload
        expect(existing_store_info.slug).to eq("test-product")
      end

      it "updates existing store info push time" do # rubocop:todo RSpec/MultipleExpectations
        original_push_time = existing_store_info.push_time
        before_time = Time.current
        described_class.perform_now(product_id)

        existing_store_info.reload
        expect(existing_store_info.push_time).not_to eq(original_push_time)
        expect(existing_store_info.push_time).to be_between(before_time, Time.current).inclusive
      end
    end

    context "when API client raises an error" do
      let(:api_error) { Shopify::Api::Client::ApiError.new("API Error") }

      before do
        allow(api_client).to receive(:create_product).and_raise(api_error)
      end

      it "propagates the error" do
        expect {
          described_class.perform_now(product_id)
        }.to raise_error(Shopify::Api::Client::ApiError, "API Error")
      end

      it "does not create or update store info on error", :aggregate_failures do
        allow(product).to receive(:link_shopify_info!)
        allow(product).to receive(:mark_shopify_pushed!)

        begin
          described_class.perform_now(product_id)
        rescue Shopify::Api::Client::ApiError
          # Expected error
        end

        expect(product).not_to have_received(:link_shopify_info!)
        expect(product).not_to have_received(:mark_shopify_pushed!)
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

    context "when serialized product is empty string" do
      before { allow(product).to receive(:shopify_payload).and_return("") }

      it "does not create API client or call create_product" do
        described_class.perform_now(product_id)
        expect(Shopify::Api::Client).not_to have_received(:new)
      end

      it "does not update store info", :aggregate_failures do
        allow(product).to receive(:link_shopify_info!)
        allow(product).to receive(:mark_shopify_pushed!)
        described_class.perform_now(product_id)
        expect(product).not_to have_received(:link_shopify_info!)
        expect(product).not_to have_received(:mark_shopify_pushed!)
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
          .with(product_id, "gid://shopify/Product/12345")
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
          .with(product_id, "gid://shopify/Product/12345")
      end
    end
  end
end
