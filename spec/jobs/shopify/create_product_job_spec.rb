require "rails_helper"

RSpec.describe Shopify::CreateProductJob do
  describe "#perform" do
    let(:product) { create(:product_with_brands) }
    let(:product_id) { product.id }
    let(:serialized_product) { {title: "Test Product", productOptions: []}.to_json }
    let(:api_client) { instance_double(Shopify::ApiClient) }
    let(:product_response) do
      {
        "id" => "gid://shopify/Product/12345",
        "handle" => "test-product"
      }
    end

    before do
      allow(Shopify::ProductSerializer).to receive(:serialize).with(product).and_return(serialized_product)
      allow(Shopify::ApiClient).to receive(:new).and_return(api_client)
      allow(api_client).to receive(:create_product).with(serialized_product).and_return(product_response)
    end

    it "finds the product by ID" do
      allow(Product).to receive(:find).with(product_id).and_return(product)
      described_class.perform_now(product_id)
      expect(Product).to have_received(:find).with(product_id)
    end

    it "serializes the product" do
      described_class.perform_now(product_id)
      expect(Shopify::ProductSerializer).to have_received(:serialize).with(product)
    end

    it "creates API client" do
      described_class.perform_now(product_id)
      expect(Shopify::ApiClient).to have_received(:new)
    end

    it "calls create_product with serialized data" do
      described_class.perform_now(product_id)
      expect(api_client).to have_received(:create_product).with(serialized_product)
    end

    it "finds or initializes store info for Shopify" do
      described_class.perform_now(product_id)

      store_info = product.store_infos.find_by(name: :shopify)
      expect(store_info).not_to be_nil
    end

    it "stores the Shopify product ID" do
      described_class.perform_now(product_id)

      store_info = product.store_infos.find_by(name: :shopify)
      expect(store_info.store_product_id).to eq("gid://shopify/Product/12345")
    end

    it "stores the product slug/handle" do
      described_class.perform_now(product_id)

      store_info = product.store_infos.find_by(name: :shopify)
      expect(store_info.slug).to eq("test-product")
    end

    it "sets the push time" do
      described_class.perform_now(product_id)

      store_info = product.store_infos.find_by(name: :shopify)
      expect(store_info.push_time).to be_within(1.second).of(Time.current)
    end

    context "when serialized product is blank" do
      before do
        allow(Shopify::ProductSerializer).to receive(:serialize).with(product).and_return(nil)
      end

      it "does not create API client or call create_product" do
        described_class.perform_now(product_id)
        expect(Shopify::ApiClient).not_to have_received(:new)
      end

      it "does not update store info" do
        allow(product.store_infos).to receive(:find_or_initialize_by)
        described_class.perform_now(product_id)
        expect(product.store_infos).not_to have_received(:find_or_initialize_by)
      end
    end

    context "when store info already exists" do
      let!(:existing_store_info) { create(:store_info, :shopify, product: product) }

      it "updates existing store info with product ID" do
        described_class.perform_now(product_id)

        existing_store_info.reload
        expect(existing_store_info.store_product_id).to eq("gid://shopify/Product/12345")
      end

      it "updates existing store info with slug" do
        described_class.perform_now(product_id)

        existing_store_info.reload
        expect(existing_store_info.slug).to eq("test-product")
      end

      it "updates existing store info push time" do
        original_push_time = existing_store_info.push_time
        described_class.perform_now(product_id)

        existing_store_info.reload
        expect(existing_store_info.push_time).not_to eq(original_push_time)
      end

      it "sets push time to current time" do
        described_class.perform_now(product_id)

        existing_store_info.reload
        expect(existing_store_info.push_time).to be_within(1.second).of(Time.current)
      end
    end

    context "when API client raises an error" do
      let(:api_error) { ShopifyApiError.new("API Error") }

      before do
        allow(api_client).to receive(:create_product).and_raise(api_error)
      end

      it "propagates the error" do
        expect {
          described_class.perform_now(product_id)
        }.to raise_error(ShopifyApiError, "API Error")
      end

      it "does not create or update store info on error" do
        allow(product.store_infos).to receive(:find_or_initialize_by)

        begin
          described_class.perform_now(product_id)
        rescue ShopifyApiError
          # Expected error
        end

        expect(product.store_infos).not_to have_received(:find_or_initialize_by)
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
      before do
        allow(Shopify::ProductSerializer).to receive(:serialize).with(product).and_return("")
      end

      it "does not create API client or call create_product" do
        described_class.perform_now(product_id)
        expect(Shopify::ApiClient).not_to have_received(:new)
      end

      it "does not update store info" do
        allow(product.store_infos).to receive(:find_or_initialize_by)
        described_class.perform_now(product_id)
        expect(product.store_infos).not_to have_received(:find_or_initialize_by)
      end
    end
  end
end
