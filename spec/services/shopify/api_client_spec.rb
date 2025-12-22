# frozen_string_literal: true
require "rails_helper"

RSpec.describe Shopify::ApiClient do
  let(:client) { described_class.new }
  let(:mock_graphql_client) { instance_double(ShopifyAPI::Clients::Graphql::Admin) }

  before do
    allow(ShopifyAPI::Clients::Graphql::Admin).to receive(:new).and_return(mock_graphql_client)
  end

  describe "#initialize" do
    it "creates a GraphQL client with Shopify credentials" do
      allow(ENV).to receive(:fetch).with("SHOPIFY_DOMAIN").and_return("test-shop.myshopify.com")
      allow(ENV).to receive(:fetch).with("SHOPIFY_API_TOKEN").and_return("test-token")

      # rubocop:todo RSpec/MessageSpies
      expect(ShopifyAPI::Clients::Graphql::Admin).to receive(:new).with(
        session: kind_of(ShopifyAPI::Auth::Session)
      )
      # rubocop:enable RSpec/MessageSpies
      described_class.new
    end
  end

  describe "#pull_product" do
    let(:product_id) { "gid://shopify/Product/123" }
    let(:product_response) do
      {
        "data" => {
          "product" => {
            "id" => product_id,
            "title" => "Test Product",
            "handle" => "test-product"
          }
        }
      }
    end

    before do
      # rubocop:todo RSpec/VerifiedDoubles
      allow(mock_graphql_client).to receive(:query).and_return(double(body: product_response))
      # rubocop:enable RSpec/VerifiedDoubles
    end

    it "queries the product with correct ID" do
      client.pull_product(product_id)

      expect(mock_graphql_client).to have_received(:query).with(
        query: kind_of(String),
        variables: {id: product_id}
      )
    end

    it "returns the product data" do
      result = client.pull_product(product_id)
      expect(result).to eq(product_response["data"]["product"])
    end

    context "when product ID is blank" do
      it "raises ArgumentError" do # rubocop:todo RSpec/MultipleExpectations
        expect { client.pull_product("") }.to raise_error(ArgumentError, "Product ID is required")
        expect { client.pull_product(nil) }.to raise_error(ArgumentError, "Product ID is required")
      end
    end
  end

  describe "#pull_order" do
    let(:order_id) { "gid://shopify/Order/456" }
    let(:order_response) do
      {
        "data" => {
          "order" => {
            "id" => order_id,
            "name" => "#1001",
            "totalPrice" => "99.99"
          }
        }
      }
    end

    before do
      # rubocop:todo RSpec/VerifiedDoubles
      allow(mock_graphql_client).to receive(:query).and_return(double(body: order_response))
      # rubocop:enable RSpec/VerifiedDoubles
    end

    it "queries the order with correct ID" do
      client.pull_order(order_id)

      expect(mock_graphql_client).to have_received(:query).with(
        query: kind_of(String),
        variables: {id: order_id}
      )
    end

    it "returns the order data" do
      result = client.pull_order(order_id)
      expect(result).to eq(order_response["data"]["order"])
    end

    context "when order ID is blank" do
      it "raises ArgumentError" do # rubocop:todo RSpec/MultipleExpectations
        expect { client.pull_order("") }.to raise_error(ArgumentError, "Order ID is required")
        expect { client.pull_order(nil) }.to raise_error(ArgumentError, "Order ID is required")
      end
    end
  end

  describe "#pull" do
    let(:resource_name) { "products" }
    let(:cursor) { "cursor123" }
    let(:batch_size) { 10 }
    let(:pull_response) do
      {
        "data" => {
          "products" => {
            "edges" => [
              {"node" => {"id" => "gid://shopify/Product/1", "title" => "Product 1"}},
              {"node" => {"id" => "gid://shopify/Product/2", "title" => "Product 2"}}
            ],
            "pageInfo" => {
              "hasNextPage" => true,
              "endCursor" => "next_cursor"
            }
          }
        }
      }
    end

    before do
      # rubocop:todo RSpec/VerifiedDoubles
      allow(mock_graphql_client).to receive(:query).and_return(double(body: pull_response))
      # rubocop:enable RSpec/VerifiedDoubles
    end

    it "queries with correct parameters" do
      client.pull(resource_name: resource_name, cursor: cursor, batch_size: batch_size)

      expect(mock_graphql_client).to have_received(:query).with(
        query: kind_of(String),
        variables: {
          first: batch_size,
          after: cursor
        }
      )
    end

    it "returns structured response with items and pagination info" do # rubocop:todo RSpec/MultipleExpectations
      result = client.pull(resource_name: resource_name, cursor: cursor, batch_size: batch_size)

      expect(result[:items]).to eq([
        {"id" => "gid://shopify/Product/1", "title" => "Product 1"},
        {"id" => "gid://shopify/Product/2", "title" => "Product 2"}
      ])
      expect(result[:has_next_page]).to be true
      expect(result[:end_cursor]).to eq("next_cursor")
    end

    context "when response uses nested resource name" do
      let(:resource_name) { "orders" }
      let(:pull_response) do
        {
          "data" => {
            "orders" => {
              "edges" => [{"node" => {"id" => "order1"}}],
              "pageInfo" => {"hasNextPage" => false, "endCursor" => nil}
            }
          }
        }
      end

      it "handles nested resource structure" do
        result = client.pull(resource_name: resource_name, cursor: nil, batch_size: 10)
        expect(result[:items]).to eq([{"id" => "order1"}])
      end
    end

    context "when resource name is blank" do
      it "raises ArgumentError" do
        expect {
          client.pull(resource_name: "", cursor: nil, batch_size: 10)
        }.to raise_error(ArgumentError, "Name is required")
      end
    end
  end

  describe "#create_product" do
    let(:serialized_product) { '{"title": "New Product", "productType": "Test"}' }
    let(:create_response) do
      {
        "data" => {
          "productCreate" => {
            "product" => {
              "id" => "gid://shopify/Product/789",
              "title" => "New Product",
              "handle" => "new-product"
            },
            "userErrors" => []
          }
        }
      }
    end

    before do
      # rubocop:todo RSpec/VerifiedDoubles
      allow(mock_graphql_client).to receive(:query).and_return(double(body: create_response))
      # rubocop:enable RSpec/VerifiedDoubles
    end

    it "queries with product create mutation" do
      client.create_product(serialized_product)

      expect(mock_graphql_client).to have_received(:query).with(
        query: kind_of(String)
      )
    end

    it "returns the created product data" do
      result = client.create_product(serialized_product)
      expect(result).to eq(create_response["data"]["productCreate"]["product"])
    end

    context "when API errors occur" do
      let(:error_response) do
        {
          "data" => {
            "productCreate" => {
              "product" => nil,
              "userErrors" => []
            }
          },
          "errors" => [
            {"message" => "API rate limit exceeded"}
          ]
        }
      end

      before do
        # rubocop:todo RSpec/VerifiedDoubles
        allow(mock_graphql_client).to receive(:query).and_return(double(body: error_response))
        # rubocop:enable RSpec/VerifiedDoubles
        allow(Sentry).to receive(:capture_message)
      end

      it "captures error in Sentry" do # rubocop:todo RSpec/MultipleExpectations
        expect(Sentry).to receive(:capture_message).with( # rubocop:todo RSpec/MessageSpies
          "Shopify productCreate failed: API rate limit exceeded",
          level: :error,
          tags: {api: "shopify", operation: "productCreate"},
          extra: hash_including(:query, :shopify_errors)
        )

        expect { client.create_product(serialized_product) }.to raise_error(ShopifyApiError)
      end

      it "raises ShopifyApiError with API error message" do
        expect {
          client.create_product(serialized_product)
        }.to raise_error(ShopifyApiError, "Failed to call the productCreate API mutation: API rate limit exceeded")
      end
    end

    context "when user errors occur" do
      let(:error_response) do
        {
          "data" => {
            "productCreate" => {
              "product" => nil,
              "userErrors" => [
                {"field" => ["title"], "message" => "Title is required"},
                {"field" => ["productType"], "message" => "Product type is invalid"}
              ]
            }
          }
        }
      end

      before do
        # rubocop:todo RSpec/VerifiedDoubles
        allow(mock_graphql_client).to receive(:query).and_return(double(body: error_response))
        # rubocop:enable RSpec/VerifiedDoubles
        allow(Sentry).to receive(:capture_message)
      end

      it "captures error in Sentry" do # rubocop:todo RSpec/MultipleExpectations
        expect(Sentry).to receive(:capture_message).with( # rubocop:todo RSpec/MessageSpies
          "Shopify productCreate failed: Title is required, Product type is invalid",
          level: :error,
          tags: {api: "shopify", operation: "productCreate"},
          extra: hash_including(:query)
        )

        expect { client.create_product(serialized_product) }.to raise_error(ShopifyApiError)
      end

      it "raises ShopifyApiError with user error messages" do
        expect {
          client.create_product(serialized_product)
        }.to raise_error(ShopifyApiError, "Failed to call the productCreate API mutation: Title is required, Product type is invalid")
      end
    end
  end

  describe "#create_product_options" do
    let(:shopify_product_id) { "gid://shopify/Product/123" }
    let(:options_data) do
      [
        {
          name: "Size",
          values: [{name: "Large"}, {name: "Medium"}]
        },
        {
          name: "Color",
          values: [{name: "Red"}]
        }
      ]
    end

    let(:success_response) do
      {
        "data" => {
          "productOptionsCreate" => {
            "userErrors" => [],
            "product" => {
              "id" => "gid://shopify/Product/123",
              "options" => [
                {
                  "id" => "gid://shopify/ProductOption/456",
                  "name" => "Size",
                  "values" => ["Large", "Medium"],
                  "position" => 1,
                  "optionValues" => [
                    {"id" => "gid://shopify/ProductOptionValue/789", "name" => "Large", "hasVariants" => true},
                    {"id" => "gid://shopify/ProductOptionValue/790", "name" => "Medium", "hasVariants" => true}
                  ]
                }
              ]
            }
          }
        }
      }
    end

    before do
      # rubocop:todo RSpec/VerifiedDoubles
      allow(mock_graphql_client).to receive(:query).and_return(double(body: success_response))
      # rubocop:enable RSpec/VerifiedDoubles
    end

    it "queries with correct parameters" do
      client.create_product_options(shopify_product_id, options_data)

      expect(mock_graphql_client).to have_received(:query).with(
        query: kind_of(String),
        variables: {
          productId: shopify_product_id,
          options: options_data,
          variantStrategy: "CREATE"
        }
      )
    end

    it "returns the product data with options and variants" do
      result = client.create_product_options(shopify_product_id, options_data)
      expect(result).to eq(success_response["data"]["productOptionsCreate"]["product"])
    end

    context "when API errors occur" do
      let(:error_response) do
        {
          "data" => {
            "productOptionsCreate" => {
              "userErrors" => []
            }
          },
          "errors" => [
            {"message" => "Product not found"}
          ]
        }
      end

      before do
        # rubocop:todo RSpec/VerifiedDoubles
        allow(mock_graphql_client).to receive(:query).and_return(double(body: error_response))
        # rubocop:enable RSpec/VerifiedDoubles
        allow(Sentry).to receive(:capture_message)
      end

      it "captures error in Sentry" do # rubocop:todo RSpec/MultipleExpectations
        expect(Sentry).to receive(:capture_message).with( # rubocop:todo RSpec/MessageSpies
          "Shopify productOptionsCreate failed: Product not found",
          level: :error,
          tags: {api: "shopify", operation: "productOptionsCreate"},
          extra: hash_including(:query, :shopify_errors)
        )

        expect { client.create_product_options(shopify_product_id, options_data) }.to raise_error(ShopifyApiError)
      end

      it "raises ShopifyApiError" do
        expect {
          client.create_product_options(shopify_product_id, options_data)
        }.to raise_error(ShopifyApiError, "Failed to call the productOptionsCreate API mutation: Product not found")
      end
    end

    context "when user errors occur" do
      let(:error_response) do
        {
          "data" => {
            "productOptionsCreate" => {
              "userErrors" => [
                {"field" => ["options"], "message" => "Can only specify a maximum of 3 options", "code" => "OPTIONS_OVER_LIMIT"}
              ]
            }
          }
        }
      end

      before do
        # rubocop:todo RSpec/VerifiedDoubles
        allow(mock_graphql_client).to receive(:query).and_return(double(body: error_response))
        # rubocop:enable RSpec/VerifiedDoubles
        allow(Sentry).to receive(:capture_message)
      end

      it "captures user errors in Sentry" do # rubocop:todo RSpec/MultipleExpectations
        expect(Sentry).to receive(:capture_message).with( # rubocop:todo RSpec/MessageSpies
          "Shopify productOptionsCreate failed: Can only specify a maximum of 3 options",
          level: :error,
          tags: {api: "shopify", operation: "productOptionsCreate"},
          extra: hash_including(:query)
        )

        expect { client.create_product_options(shopify_product_id, options_data) }.to raise_error(ShopifyApiError)
      end

      it "raises ShopifyApiError with user error message" do
        expect {
          client.create_product_options(shopify_product_id, options_data)
        }.to raise_error(ShopifyApiError, "Failed to call the productOptionsCreate API mutation: Can only specify a maximum of 3 options")
      end
    end
  end

  describe "#gql_query" do
    it "returns product query when name is 'product'" do # rubocop:todo RSpec/MultipleExpectations
      query = client.send(:gql_query, "product")
      expect(query).to include("query($id: ID!)")
      expect(query).to include("product(id: $id)")
    end

    it "returns products query when name is 'products'" do # rubocop:todo RSpec/MultipleExpectations
      query = client.send(:gql_query, "products")
      expect(query).to include("query($first: Int!, $after: String)")
      expect(query).to include("products(")
    end

    it "returns order query when name is 'order'" do # rubocop:todo RSpec/MultipleExpectations
      query = client.send(:gql_query, "order")
      expect(query).to include("query($id: ID!)")
      expect(query).to include("sale(id: $id)")
    end

    it "returns orders query when name is 'orders'" do # rubocop:todo RSpec/MultipleExpectations
      query = client.send(:gql_query, "orders")
      expect(query).to include("query($first: Int!, $after: String)")
      expect(query).to include("orders(")
    end

    context "when query name is invalid" do
      it "raises ArgumentError" do
        expect {
          client.send(:gql_query, "invalid_query")
        }.to raise_error(ArgumentError, "Invalid query name: invalid_query")
      end
    end
  end
end
