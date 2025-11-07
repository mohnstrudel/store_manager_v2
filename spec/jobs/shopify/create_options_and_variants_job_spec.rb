require "rails_helper"

RSpec.describe Shopify::CreateOptionsAndVariantsJob do
  describe "#perform" do
    let(:product) { create(:product_with_brands) }
    let(:product_id) { product.id }
    let(:shopify_product_id) { "gid://shopify/Product/12345" }
    let(:api_client) { instance_spy(Shopify::ApiClient) }

    # Test data for options
    let(:size) { create(:size, value: "Large") }
    let(:version) { create(:version, value: "v1") }
    let(:color) { create(:color, value: "Red") }
    let(:product_size) { create(:product_size, product: product, size: size) }
    let(:product_version) { create(:product_version, product: product, version: version) }
    let(:product_color) { create(:product_color, product: product, color: color) }
    let(:edition) do
      create(:edition, product: product, size: size, version: version, color: color)
    end

    # Expected serialized options
    let(:expected_options) do
      [
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
    end

    # Mock API response
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

    before do
      allow(Shopify::ApiClient).to receive(:new).and_return(api_client)
    end

    it "finds the product by ID" do
      allow(Product).to receive(:find).with(product_id).and_return(product)
      described_class.perform_now(product_id, shopify_product_id)
      expect(Product).to have_received(:find).with(product_id)
    end

    it "creates API client" do
      described_class.perform_now(product_id, shopify_product_id)
      expect(Shopify::ApiClient).to have_received(:new)
    end

    it "calls create_product_options with correct parameters" do
      # Setup product with all options
      product_size
      product_version
      product_color
      product.editions << edition

      allow(api_client).to receive(:create_product_options)
        .with(shopify_product_id, expected_options)
        .and_return(options_response)

      described_class.perform_now(product_id, shopify_product_id)
      expect(api_client).to have_received(:create_product_options)
        .with(shopify_product_id, expected_options)
    end

    context "when product has all option types" do
      before do
        product_size
        product_version
        product_color
        product.editions << edition

        allow(api_client).to receive(:create_product_options)
          .with(shopify_product_id, expected_options)
          .and_return(options_response)
      end

      it "serializes all available options" do
        described_class.perform_now(product_id, shopify_product_id)

        expect(api_client).to have_received(:create_product_options)
          .with(shopify_product_id, array_including(
            hash_including(name: "Size", values: array_including(hash_including(name: "Large"))),
            hash_including(name: "Version", values: array_including(hash_including(name: "v1"))),
            hash_including(name: "Color", values: array_including(hash_including(name: "Red")))
          ))
      end

      it "creates store info for sizes" do # rubocop:todo RSpec/MultipleExpectations
        described_class.perform_now(product_id, shopify_product_id)

        product_size.reload
        size_store_info = product_size.store_infos.find_by(store_name: :shopify)
        expect(size_store_info).to be_present
        expect(size_store_info.store_id).to eq("gid://shopify/ProductOptionValue/1")
      end

      it "creates store info for versions" do # rubocop:todo RSpec/MultipleExpectations
        described_class.perform_now(product_id, shopify_product_id)

        product_version.reload
        version_store_info = product_version.store_infos.find_by(store_name: :shopify)
        expect(version_store_info).to be_present
        expect(version_store_info.store_id).to eq("gid://shopify/ProductOptionValue/2")
      end

      it "creates store info for colors" do # rubocop:todo RSpec/MultipleExpectations
        described_class.perform_now(product_id, shopify_product_id)

        product_color.reload
        color_store_info = product_color.store_infos.find_by(store_name: :shopify)
        expect(color_store_info).to be_present
        expect(color_store_info.store_id).to eq("gid://shopify/ProductOptionValue/3")
      end

      it "creates store info for edition variants" do # rubocop:todo RSpec/MultipleExpectations
        described_class.perform_now(product_id, shopify_product_id)

        edition.reload
        edition_store_info = edition.store_infos.find_by(store_name: :shopify)
        expect(edition_store_info).to be_present
        expect(edition_store_info.store_id).to eq("gid://shopify/ProductVariant/1")
      end

      it "sets push_time for all created store infos" do
        before_time = Time.current
        described_class.perform_now(product_id, shopify_product_id)

        [product_size, product_version, product_color, edition].each do |record|
          store_info = record.reload.store_infos.find_by(store_name: :shopify)
          expect(store_info.push_time).to be_between(before_time, Time.current).inclusive
        end
      end
    end

    context "when product has only sizes" do
      let(:expected_size_only_options) do
        [
          {
            name: "Size",
            values: [{name: "Large"}]
          }
        ]
      end

      let(:size_only_response) do
        {
          "options" => [
            {
              "id" => "gid://shopify/ProductOption/1",
              "name" => "Size",
              "optionValues" => [
                {"id" => "gid://shopify/ProductOptionValue/1", "name" => "Large"}
              ]
            }
          ],
          "variants" => {
            "nodes" => []
          }
        }
      end

      before do
        product_size
        allow(api_client).to receive(:create_product_options)
          .with(shopify_product_id, expected_size_only_options)
          .and_return(size_only_response)
      end

      it "calls create_product_options with only size option" do
        described_class.perform_now(product_id, shopify_product_id)
        expect(api_client).to have_received(:create_product_options)
          .with(shopify_product_id, expected_size_only_options)
      end

      it "creates store info only for size" do # rubocop:todo RSpec/MultipleExpectations
        described_class.perform_now(product_id, shopify_product_id)

        product_size.reload
        size_store_info = product_size.store_infos.find_by(store_name: :shopify)
        expect(size_store_info).to be_present
        expect(size_store_info.store_id).to eq("gid://shopify/ProductOptionValue/1")
      end
    end

    context "when product has no options" do
      it "does not call create_product_options" do
        described_class.perform_now(product_id, shopify_product_id)
        expect(api_client).not_to have_received(:create_product_options)
      end

      it "returns true" do
        result = described_class.perform_now(product_id, shopify_product_id)
        expect(result).to be true
      end
    end

    context "when API client raises an error" do
      let(:api_error) { ShopifyApiError.new("Options creation failed") }

      before do
        product_size
        allow(api_client).to receive(:create_product_options).and_raise(api_error)
      end

      it "propagates the error" do
        expect {
          described_class.perform_now(product_id, shopify_product_id)
        }.to raise_error(ShopifyApiError, "Options creation failed")
      end

      it "does not create any store infos on error" do
        allow(StoreInfo).to receive(:find_or_initialize_by)

        begin
          described_class.perform_now(product_id, shopify_product_id)
        rescue ShopifyApiError
          # Expected error
        end

        expect(StoreInfo).not_to have_received(:find_or_initialize_by)
      end
    end

    context "when product is not found" do
      it "raises ActiveRecord::RecordNotFound" do
        expect {
          described_class.perform_now(99999, shopify_product_id)
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when edition cannot be matched to variant" do
      let(:unmatched_edition) do
        create(:edition, product: product, size: create(:size, value: "Small"))
      end

      let(:variant_response) do
        {
          "options" => [
            {
              "id" => "gid://shopify/ProductOption/1",
              "name" => "Size",
              "optionValues" => [
                {"id" => "gid://shopify/ProductOptionValue/1", "name" => "Large"}
              ]
            }
          ],
          "variants" => {
            "nodes" => [
              {
                "id" => "gid://shopify/ProductVariant/1",
                "selectedOptions" => [
                  {"name" => "Size", "value" => "Large"}
                ]
              }
            ]
          }
        }
      end

      before do
        product_size
        product.editions << unmatched_edition
        allow(api_client).to receive(:create_product_options).and_return(variant_response)
      end

      it "does not create store info for unmatched edition" do
        described_class.perform_now(product_id, shopify_product_id)

        unmatched_edition.reload
        edition_store_info = unmatched_edition.store_infos.find_by(store_name: :shopify)
        expect(edition_store_info).to be_nil
      end

      it "still creates store info for matched options" do
        described_class.perform_now(product_id, shopify_product_id)

        product_size.reload
        size_store_info = product_size.store_infos.find_by(store_name: :shopify)
        expect(size_store_info).to be_present
      end
    end

    context "when store info already exists for options" do
      let!(:existing_size_store_info) do
        create(:store_info, :shopify, storable: product_size, store_id: "old_id")
      end

      let(:size_only_options) do
        [
          {
            name: "Size",
            values: [{name: "Large"}]
          }
        ]
      end

      let(:size_only_response) do
        {
          "options" => [
            {
              "id" => "gid://shopify/ProductOption/1",
              "name" => "Size",
              "optionValues" => [
                {"id" => "gid://shopify/ProductOptionValue/1", "name" => "Large"}
              ]
            }
          ],
          "variants" => {
            "nodes" => []
          }
        }
      end

      before do
        product_size
        allow(api_client).to receive(:create_product_options)
          .with(shopify_product_id, size_only_options)
          .and_return(size_only_response)
      end

      it "updates existing store info" do # rubocop:todo RSpec/MultipleExpectations
        described_class.perform_now(product_id, shopify_product_id)

        existing_size_store_info.reload
        expect(existing_size_store_info.store_id).to eq("gid://shopify/ProductOptionValue/1")
        expect(existing_size_store_info.push_time).to be_within(1.second).of(Time.current)
      end
    end

    context "when store info already exists for editions" do
      let!(:existing_edition_store_info) do
        create(:store_info, :shopify, storable: edition, store_id: "old_variant_id")
      end

      before do
        product_size
        product_version
        product_color
        product.editions << edition

        allow(api_client).to receive(:create_product_options)
          .with(shopify_product_id, expected_options)
          .and_return(options_response)
      end

      it "updates existing edition store info" do # rubocop:todo RSpec/MultipleExpectations
        described_class.perform_now(product_id, shopify_product_id)

        existing_edition_store_info.reload
        expect(existing_edition_store_info.store_id).to eq("gid://shopify/ProductVariant/1")
        expect(existing_edition_store_info.push_time).to be_within(1.second).of(Time.current)
      end
    end

    context "when API returns empty variants" do
      let(:empty_variants_response) do
        {
          "options" => [
            {
              "id" => "gid://shopify/ProductOption/1",
              "name" => "Size",
              "optionValues" => [
                {"id" => "gid://shopify/ProductOptionValue/1", "name" => "Large"}
              ]
            }
          ],
          "variants" => {
            "nodes" => []
          }
        }
      end

      before do
        product_size
        allow(api_client).to receive(:create_product_options).and_return(empty_variants_response)
      end

      it "creates store info for options but no editions" do # rubocop:todo RSpec/MultipleExpectations
        described_class.perform_now(product_id, shopify_product_id)

        product_size.reload
        size_store_info = product_size.store_infos.find_by(store_name: :shopify)
        expect(size_store_info).to be_present

        expect(Edition.where(product: product).none? { |e|
          e.store_infos.exists?(store_name: :shopify)
        }).to be true
      end
    end
  end
end
