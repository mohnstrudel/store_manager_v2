require "rails_helper"

RSpec.describe SyncShopifyProductsJob do
  include ActiveJob::TestHelper

  let(:job) { described_class.new }
  let(:api_response) { eval(file_fixture("shopify_api_products.rb").read) }
  let(:parsed_products) {
    eval(file_fixture("shopify_parsed_products.rb").read)
  }

  let(:mock_response_data) {
    {
      products: api_response,
      has_next_page: false,
      end_cursor: "end_cursor_value"
    }
  }

  describe "#perform" do
    before do
      allow(job).to receive(:fetch_shopify_products).and_return(mock_response_data)
      allow(SyncShopifyVariationsJob).to receive(:perform_later)
      allow(SyncShopifyImagesJob).to receive(:perform_later)
      allow(described_class).to receive(:perform_later)

      perform_enqueued_jobs do
        job.perform
      end
    end

    it "creates correct number of products" do
      expect(Product.count).to eq(parsed_products.size)
    end

    it "creates products with correct attributes" do
      parsed_products.each do |parsed_product|
        product = Product.find_by(shopify_id: parsed_product[:shopify_id])

        expect(product).to have_attributes(
          title: parsed_product[:title],
          store_link: parsed_product[:store_link]
        )

        expect(product.shape.title).to eq(parsed_product[:shape])
        expect(product.franchise.title).to eq(parsed_product[:franchise])

        if parsed_product[:brand]
          expect(product.brands.pluck(:title)).to include(
            parsed_product[:brand]
          )
        end

        if parsed_product[:size]
          expect(product.sizes.pluck(:value)).to include(parsed_product[:size])
        end
      end
    end

    it "triggers sync jobs for variations and images" do
      Product.all.each do |product|
        parsed_product = parsed_products.find { |p|
          p[:shopify_id] == product.shopify_id
        }

        expect(SyncShopifyVariationsJob).to have_received(:perform_later)
          .with(product, parsed_product[:variations])
        expect(SyncShopifyImagesJob).to have_received(:perform_later)
          .with(product, parsed_product[:images])
      end
    end

    it "updates existing products instead of creating duplicates" do
      initial_count = Product.count

      modified_api_response = api_response.deep_dup
      modified_api_response.first["title"] = "Stellar Blade - Updated Title | 1:4 Resin Statue | von Light and Dust Studio"

      modified_response_data = mock_response_data.deep_dup
      modified_response_data[:products] = modified_api_response

      allow(job).to receive(:fetch_shopify_products).and_return(modified_response_data)

      job.perform

      expect(Product.count).to eq(initial_count)
      expect(Product.find_by(shopify_id: modified_api_response.first["id"]))
        .to have_attributes(title: "Updated Title")
    end
  end
end
