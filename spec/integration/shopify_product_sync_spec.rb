# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Shopify Job Integration" do
  describe "Complete product sync workflow" do
    let(:product) { create(:product_with_brands) }
    let(:size) { create(:size, value: "Large") }
    let(:version) { create(:version, value: "v1") }
    let(:color) { create(:color, value: "Red") }
    let(:product_size) { create(:product_size, product: product, size: size) }
    let(:product_version) { create(:product_version, product: product, version: version) }
    let(:product_color) { create(:product_color, product: product, color: color) }
    let(:variant) do
      create(:variant, product: product, size: size, version: version, color: color)
    end

    let(:product_response) do
      {
        "id" => "gid://shopify/Product/12345",
        "handle" => "test-product"
      }
    end

    let(:options_response) do
      {
        "options" => [
          {
            "id" => "gid://shopify/ProductOption/1",
            "name" => "Size",
            "optionValues" => [
              {"id" => "gid://shopify/ProductOptionValue/1", "name" => "Large"}
            ]
          },
          {
            "id" => "gid://shopify/ProductOption/2",
            "name" => "Version",
            "optionValues" => [
              {"id" => "gid://shopify/ProductOptionValue/2", "name" => "v1"}
            ]
          },
          {
            "id" => "gid://shopify/ProductOption/3",
            "name" => "Color",
            "optionValues" => [
              {"id" => "gid://shopify/ProductOptionValue/3", "name" => "Red"}
            ]
          }
        ],
        "variants" => {
          "nodes" => [
            {
              "id" => "gid://shopify/ProductVariant/1",
              "selectedOptions" => [
                {"name" => "Size", "value" => "Large"},
                {"name" => "Version", "value" => "v1"},
                {"name" => "Color", "value" => "Red"}
              ]
            }
          ]
        }
      }
    end

    let(:serialized_product) do
      {
        "title" => "Test Franchise - Test Product | Resin Test Shape | by Test Brand"
      }
    end

    before do
      product_size
      product_version
      product_color
      product.variants << variant

      allow_any_instance_of(Product).to receive(:shopify_payload).and_return(serialized_product)
    end

    context "when both jobs execute successfully" do
      before do
        api_client = instance_spy(Shopify::Api::Client)
        allow(Shopify::Api::Client).to receive(:new).and_return(api_client)

        allow(api_client).to receive(:create_product)
          .with(serialized_product)
          .and_return(product_response)

        expected_options = [
          {
            name: "Size",
            values: [{name: "Large"}]
          },
          {
            name: "Version",
            values: [{name: "v1"}]
          },
          {
            name: "Color",
            values: [{name: "Red"}]
          }
        ]
        allow(api_client).to receive(:create_product_options)
          .with("gid://shopify/Product/12345", expected_options)
          .and_return(options_response)
      end

      it "successfully creates complete product with options and variants" do # rubocop:todo RSpec/MultipleExpectations
        expect {
          Shopify::CreateProductJob.perform_now(product.id)
        }.not_to raise_error

        product_store_info = product.store_infos.find_by(store_name: :shopify)
        expect(product_store_info).to be_present
        expect(product_store_info.store_id).to eq("gid://shopify/Product/12345")
        expect(product_store_info.slug).to eq("test-product")

        expect {
          Shopify::CreateOptionsAndVariantsJob.perform_now(
            product.id,
            "gid://shopify/Product/12345"
          )
        }.not_to raise_error

        product_size.reload
        size_store_info = product_size.store_infos.find_by(store_name: :shopify)
        expect(size_store_info).to be_present
        expect(size_store_info.store_id).to eq("gid://shopify/ProductOptionValue/1")

        product_version.reload
        version_store_info = product_version.store_infos.find_by(store_name: :shopify)
        expect(version_store_info).to be_present
        expect(version_store_info.store_id).to eq("gid://shopify/ProductOptionValue/2")

        product_color.reload
        color_store_info = product_color.store_infos.find_by(store_name: :shopify)
        expect(color_store_info).to be_present
        expect(color_store_info.store_id).to eq("gid://shopify/ProductOptionValue/3")

        variant.reload
        variant_store_info = variant.store_infos.find_by(store_name: :shopify)
        expect(variant_store_info).to be_present
        expect(variant_store_info.store_id).to eq("gid://shopify/ProductVariant/1")

        [product_store_info, size_store_info, version_store_info, color_store_info, variant_store_info].each do |store_info|
          expect(store_info.push_time).to be_within(1.second).of(Time.current)
        end
      end
    end

    context "when first job fails" do
      before do
        api_client = instance_spy(Shopify::Api::Client)
        allow(Shopify::Api::Client).to receive(:new).and_return(api_client)
        allow(api_client).to receive(:create_product).and_raise(Shopify::Api::Client::ApiError, "API Error")
      end

      it "does not create any store infos" do # rubocop:todo RSpec/MultipleExpectations
        initial_store_info_count = StoreInfo.count

        expect {
          Shopify::CreateProductJob.perform_now(product.id)
        }.to raise_error(Shopify::Api::Client::ApiError, "API Error")

        expect(StoreInfo.count).to eq(initial_store_info_count)
      end

      it "does not execute second job" do # rubocop:todo RSpec/MultipleExpectations
        allow(Shopify::CreateOptionsAndVariantsJob).to receive(:perform_later)

        expect {
          Shopify::CreateProductJob.perform_now(product.id)
        }.to raise_error(Shopify::Api::Client::ApiError, "API Error")

        expect(Shopify::CreateOptionsAndVariantsJob).not_to have_received(:perform_later)
      end
    end

    context "when first job succeeds but second job fails" do
      before do
        product_size.store_infos.where(store_name: :shopify).destroy_all
        product_version.store_infos.where(store_name: :shopify).destroy_all
        product_color.store_infos.where(store_name: :shopify).destroy_all
        variant.store_infos.where(store_name: :shopify).destroy_all

        api_client = instance_spy(Shopify::Api::Client)
        allow(Shopify::Api::Client).to receive(:new).and_return(api_client)
        allow(api_client).to receive(:create_product)
          .with(serialized_product)
          .and_return(product_response)

        allow(api_client).to receive(:create_product_options).and_raise(Shopify::Api::Client::ApiError, "Options API Error")
      end

      it "leaves product store info intact but no option store infos" do # rubocop:todo RSpec/MultipleExpectations
        Shopify::CreateProductJob.perform_now(product.id)

        product_store_info = product.store_infos.find_by(store_name: :shopify)
        expect(product_store_info).to be_present

        expect {
          Shopify::CreateOptionsAndVariantsJob.perform_now(
            product.id,
            "gid://shopify/Product/12345"
          )
        }.to raise_error(Shopify::Api::Client::ApiError, "Options API Error")

        expect(product_size.store_infos.where(store_name: :shopify)).to be_none
        expect(product_version.store_infos.where(store_name: :shopify)).to be_none
        expect(product_color.store_infos.where(store_name: :shopify)).to be_none
        expect(variant.store_infos.where(store_name: :shopify)).to be_none
      end
    end

    context "when product has no options" do
      let(:product_without_options) { create(:product_with_brands) }
      let(:serialized_simple_product) do
        {
          "title" => "Simple Test Product | Resin Test Shape | by Test Brand"
        }
      end

      before do
        allow_any_instance_of(Product).to receive(:shopify_payload).and_return(serialized_simple_product)

        api_client = instance_spy(Shopify::Api::Client)
        allow(Shopify::Api::Client).to receive(:new).and_return(api_client)
        allow(api_client).to receive(:create_product)
          .with(serialized_simple_product)
          .and_return(product_response)
      end

      it "only creates product without enqueuing options job" do # rubocop:todo RSpec/MultipleExpectations
        allow(Shopify::CreateOptionsAndVariantsJob).to receive(:perform_later)

        Shopify::CreateProductJob.perform_now(product_without_options.id)

        expect(Shopify::CreateOptionsAndVariantsJob).not_to have_received(:perform_later)

        product_store_info = product_without_options.store_infos.find_by(store_name: :shopify)
        expect(product_store_info).to be_present
        expect(product_store_info.store_id).to eq("gid://shopify/Product/12345")
      end
    end

    context "when using ActiveJob for job chaining" do
      before do
        api_client = instance_spy(Shopify::Api::Client)
        allow(Shopify::Api::Client).to receive(:new).and_return(api_client)

        allow(api_client).to receive(:create_product)
          .with(serialized_product)
          .and_return(product_response)

        expected_options = [
          {
            name: "Size",
            values: [{name: "Large"}]
          },
          {
            name: "Version",
            values: [{name: "v1"}]
          },
          {
            name: "Color",
            values: [{name: "Red"}]
          }
        ]
        allow(api_client).to receive(:create_product_options)
          .with("gid://shopify/Product/12345", expected_options)
          .and_return(options_response)

        ActiveJob::Base.queue_adapter = :inline
      end

      after do
        ActiveJob::Base.queue_adapter = :test
      end

      it "executes both jobs in sequence when using perform_later" do # rubocop:todo RSpec/MultipleExpectations
        expect {
          Shopify::CreateProductJob.perform_later(product.id)
        }.not_to raise_error

        product_store_info = product.store_infos.find_by(store_name: :shopify)
        expect(product_store_info).to be_present

        product_size.reload
        size_store_info = product_size.store_infos.find_by(store_name: :shopify)
        expect(size_store_info).to be_present

        variant.reload
        variant_store_info = variant.store_infos.find_by(store_name: :shopify)
        expect(variant_store_info).to be_present
      end
    end

    context "when testing idempotency" do
      before do
        api_client = instance_spy(Shopify::Api::Client)
        allow(Shopify::Api::Client).to receive(:new).and_return(api_client)

        allow(api_client).to receive(:create_product)
          .with(serialized_product)
          .and_return(product_response)

        expected_options = [
          {
            name: "Size",
            values: [{name: "Large"}]
          },
          {
            name: "Version",
            values: [{name: "v1"}]
          },
          {
            name: "Color",
            values: [{name: "Red"}]
          }
        ]
        allow(api_client).to receive(:create_product_options)
          .with("gid://shopify/Product/12345", expected_options)
          .and_return(options_response)
      end

      it "can safely run both jobs multiple times" do # rubocop:todo RSpec/MultipleExpectations
        Shopify::CreateProductJob.perform_now(product.id)
        Shopify::CreateOptionsAndVariantsJob.perform_now(product.id, "gid://shopify/Product/12345")

        initial_store_info_count = StoreInfo.where(store_name: :shopify).count

        Shopify::CreateProductJob.perform_now(product.id)
        Shopify::CreateOptionsAndVariantsJob.perform_now(product.id, "gid://shopify/Product/12345")

        final_store_info_count = StoreInfo.where(store_name: :shopify).count
        expect(final_store_info_count).to eq(initial_store_info_count)

        StoreInfo.where(store_name: :shopify).find_each do |store_info|
          expect(store_info.push_time).to be_within(1.second).of(Time.current)
        end
      end
    end
  end
end
