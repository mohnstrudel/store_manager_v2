require "rails_helper"

RSpec.describe Shopify::ApiClient do
  before do
    allow(ENV).to receive(:fetch).with("SHOPIFY_DOMAIN").and_return("test-store.myshopify.com")
    allow(ENV).to receive(:fetch).with("SHOPIFY_API_TOKEN").and_return("test-token")
  end

  describe "#initialize" do
    it "initializes a ShopifyAPI GraphQL client with correct session" do
      session_double = instance_double(ShopifyAPI::Auth::Session)
      client_double = instance_double(ShopifyAPI::Clients::Graphql::Admin)

      allow(ShopifyAPI::Auth::Session).to receive(:new).with(
        shop: "test-store.myshopify.com",
        access_token: "test-token"
      ).and_return(session_double)

      allow(ShopifyAPI::Clients::Graphql::Admin).to receive(:new).with(
        session: session_double
      ).and_return(client_double)

      described_class.new

      expect(ShopifyAPI::Auth::Session).to have_received(:new).with(
        shop: "test-store.myshopify.com",
        access_token: "test-token"
      )
    end

    it "creates GraphQL admin client with correct session" do
      session_double = instance_double(ShopifyAPI::Auth::Session)
      client_double = instance_double(ShopifyAPI::Clients::Graphql::Admin)

      allow(ShopifyAPI::Auth::Session).to receive(:new).and_return(session_double)
      allow(ShopifyAPI::Clients::Graphql::Admin).to receive(:new).and_return(client_double)

      described_class.new

      expect(ShopifyAPI::Clients::Graphql::Admin).to have_received(:new).with(
        session: session_double
      )
    end
  end

  describe "#pull" do
    let(:api_client) { described_class.new }
    let(:graphql_client) { instance_double(ShopifyAPI::Clients::Graphql::Admin) }
    let(:response) do
      instance_double(
        ShopifyAPI::Clients::HttpResponse,
        body: {
          "data" => {
            "products" => {
              "edges" => [
                {"node" => {"id" => "gid://shopify/Product/1"}},
                {"node" => {"id" => "gid://shopify/Product/2"}}
              ],
              "pageInfo" => {
                "hasNextPage" => true,
                "endCursor" => "cursor123"
              }
            }
          }
        }
      )
    end

    before do
      allow(ShopifyAPI::Auth::Session).to receive(:new).and_return(instance_double(ShopifyAPI::Auth::Session))
      allow(ShopifyAPI::Clients::Graphql::Admin).to receive(:new).and_return(graphql_client)
      allow(graphql_client).to receive(:query).and_return(response)
      allow(api_client).to receive(:gql_query).and_return("query { products { edges { node { id } } } }")
    end

    it "calls the GraphQL client with correct parameters" do
      api_client.pull(resource_name: "products", cursor: "cursor123", batch_size: 10)

      expect(graphql_client).to have_received(:query).with(
        query: "query { products { edges { node { id } } } }",
        variables: {
          first: 10,
          after: "cursor123"
        }
      )
    end

    it "transforms the response into the expected format" do
      result = api_client.pull(resource_name: "products", cursor: nil, batch_size: 10)

      expect(result).to eq({
        items: [
          {"id" => "gid://shopify/Product/1"},
          {"id" => "gid://shopify/Product/2"}
        ],
        has_next_page: true,
        end_cursor: "cursor123"
      })
    end

    it "raises an error when resource_name is blank" do
      expect {
        api_client.pull(resource_name: "", cursor: nil, batch_size: 10)
      }.to raise_error(ArgumentError, "Name is required")
    end
  end

  describe "#pull_product" do
    let(:api_client) { described_class.new }
    let(:graphql_client) { instance_double(ShopifyAPI::Clients::Graphql::Admin) }
    let(:product_id) { "gid://shopify/Product/123" }
    let(:response) do
      instance_double(
        ShopifyAPI::Clients::HttpResponse,
        body: {
          "data" => {
            "product" => {
              "id" => product_id,
              "title" => "Test Product"
            }
          }
        }
      )
    end

    before do
      allow(ShopifyAPI::Auth::Session).to receive(:new).and_return(instance_double(ShopifyAPI::Auth::Session))
      allow(ShopifyAPI::Clients::Graphql::Admin).to receive(:new).and_return(graphql_client)
      allow(graphql_client).to receive(:query).and_return(response)
      allow(api_client).to receive(:gql_query).with("product").and_return("query($id: ID!) { product(id: $id) { id title } }")
    end

    it "calls the GraphQL client with correct parameters" do
      api_client.pull_product(product_id)

      expect(graphql_client).to have_received(:query).with(
        query: "query($id: ID!) { product(id: $id) { id title } }",
        variables: {id: product_id}
      )
    end

    it "returns the product data from the response" do
      result = api_client.pull_product(product_id)
      expect(result).to eq({"id" => product_id, "title" => "Test Product"})
    end

    it "raises an error when product_id is blank" do
      expect {
        api_client.pull_product("")
      }.to raise_error(ArgumentError, "Product ID is required")
    end
  end

  describe "#pull_order" do
    let(:api_client) { described_class.new }
    let(:graphql_client) { instance_double(ShopifyAPI::Clients::Graphql::Admin) }
    let(:order_id) { "gid://shopify/Order/123" }
    let(:response) do
      instance_double(
        ShopifyAPI::Clients::HttpResponse,
        body: {
          "data" => {
            "order" => {
              "id" => order_id,
              "name" => "#1001"
            }
          }
        }
      )
    end

    before do
      allow(ShopifyAPI::Auth::Session).to receive(:new).and_return(instance_double(ShopifyAPI::Auth::Session))
      allow(ShopifyAPI::Clients::Graphql::Admin).to receive(:new).and_return(graphql_client)
      allow(graphql_client).to receive(:query).and_return(response)
      allow(api_client).to receive(:gql_query).with("order").and_return("query($id: ID!) { order(id: $id) { id name } }")
    end

    it "calls the GraphQL client with correct parameters" do
      api_client.pull_order(order_id)

      expect(graphql_client).to have_received(:query).with(
        query: "query($id: ID!) { order(id: $id) { id name } }",
        variables: {id: order_id}
      )
    end

    it "returns the order data from the response" do
      result = api_client.pull_order(order_id)
      expect(result).to eq({"id" => order_id, "name" => "#1001"})
    end

    it "raises an error when order_id is blank" do
      expect {
        api_client.pull_order("")
      }.to raise_error(ArgumentError, "Order ID is required")
    end
  end

  describe "#create_product" do
    let(:api_client) { described_class.new }
    let(:graphql_client) { instance_double(ShopifyAPI::Clients::Graphql::Admin) }
    let(:serialized_product) { '{title: "Test Product", productOptions: []}' }
    let(:product_response) do
      {
        "id" => "gid://shopify/Product/12345",
        "title" => "Test Product",
        "handle" => "test-product"
      }
    end
    let(:response) do
      instance_double(
        ShopifyAPI::Clients::HttpResponse,
        body: {
          "data" => {
            "productCreate" => {
              "product" => product_response,
              "userErrors" => []
            }
          }
        }
      )
    end

    before do
      allow(ShopifyAPI::Auth::Session).to receive(:new).and_return(instance_double(ShopifyAPI::Auth::Session))
      allow(ShopifyAPI::Clients::Graphql::Admin).to receive(:new).and_return(graphql_client)
      allow(graphql_client).to receive(:query).and_return(response)
      allow(Sentry).to receive(:capture_message)
    end

    it "calls the GraphQL client with correct mutation query" do
      expected_query = <<~GQL
        mutation {
          productCreate(product: #{serialized_product}) {
            product {
              id
              title
              handle
            }
            userErrors {
              field
              message
            }
          }
        }
      GQL

      api_client.create_product(serialized_product)

      expect(graphql_client).to have_received(:query).with(query: expected_query)
    end

    it "returns the product data from the response" do
      result = api_client.create_product(serialized_product)
      expect(result).to eq(product_response)
    end

    context "when API errors occur" do
      let(:error_response) do
        instance_double(
          ShopifyAPI::Clients::HttpResponse,
          body: {
            "data" => {
              "productCreate" => {
                "product" => nil,
                "userErrors" => []
              }
            },
            "errors" => [
              {"message" => "API Error 1"},
              {"message" => "API Error 2"}
            ]
          }
        )
      end

      before do
        allow(graphql_client).to receive(:query).and_return(error_response)
      end

      it "raises ShopifyApiError with combined error messages" do
        expect {
          api_client.create_product(serialized_product)
        }.to raise_error(ShopifyApiError, "Failed to call the productCreate API mutation: API Error 1, API Error 2")
      end

      it "captures error message in Sentry when API errors occur" do # rubocop:disable RSpec/MultipleExpectations
        expect {
          api_client.create_product(serialized_product)
        }.to raise_error(ShopifyApiError)

        expect(Sentry).to have_received(:capture_message).with(
          "Shopify productCreate failed: API Error 1, API Error 2",
          level: :error,
          tags: {
            api: "shopify",
            operation: "productCreate"
          },
          extra: {
            query: anything,
            shopify_errors: [{"message" => "API Error 1"}, {"message" => "API Error 2"}]
          }
        )
      end
    end

    context "when user errors occur" do
      let(:user_error_response) do
        instance_double(
          ShopifyAPI::Clients::HttpResponse,
          body: {
            "data" => {
              "productCreate" => {
                "product" => nil,
                "userErrors" => [
                  {"field" => ["title"], "message" => "Title is required"},
                  {"field" => ["productOptions"], "message" => "Invalid options"}
                ]
              }
            }
          }
        )
      end

      before do
        allow(graphql_client).to receive(:query).and_return(user_error_response)
      end

      it "raises ShopifyApiError with combined user error messages" do
        expect {
          api_client.create_product(serialized_product)
        }.to raise_error(ShopifyApiError, "Failed to call the productCreate API mutation: Title is required, Invalid options")
      end

      it "captures user error message in Sentry when user errors occur" do # rubocop:disable RSpec/MultipleExpectations
        expect {
          api_client.create_product(serialized_product)
        }.to raise_error(ShopifyApiError)

        expect(Sentry).to have_received(:capture_message).with(
          "Shopify productCreate failed: Title is required, Invalid options",
          level: :error,
          tags: {
            api: "shopify",
            operation: "productCreate"
          },
          extra: {
            query: anything,
            shopify_errors: nil
          }
        )
      end
    end

    context "when no errors occur" do
      it "does not capture any Sentry messages" do
        api_client.create_product(serialized_product)
        expect(Sentry).not_to have_received(:capture_message)
      end
    end
  end

  describe "#gql_query" do
    let(:api_client) { described_class.new }

    before do
      allow(ShopifyAPI::Auth::Session).to receive(:new).and_return(instance_double(ShopifyAPI::Auth::Session))
      allow(ShopifyAPI::Clients::Graphql::Admin).to receive(:new).and_return(instance_double(ShopifyAPI::Clients::Graphql::Admin))
    end

    it "returns the product query when name is 'product'" do
      query = api_client.gql_query("product")
      expect(query).to include("query($id: ID!)")
    end

    it "includes product field definitions in product query" do
      query = api_client.gql_query("product")
      expect(query).to include("product(id: $id)")
    end

    it "returns the products query when name is 'products'" do
      query = api_client.gql_query("products")
      expect(query).to include("query($first: Int!, $after: String)")
    end

    it "includes products field definitions in products query" do
      query = api_client.gql_query("products")
      expect(query).to include("products(")
    end

    it "returns the order query when name is 'order'" do
      query = api_client.gql_query("order")
      expect(query).to include("query($id: ID!)")
    end

    it "includes sale field definitions in order query" do
      query = api_client.gql_query("order")
      expect(query).to include("sale(id: $id)")
    end

    it "returns the orders query when name is 'orders'" do
      query = api_client.gql_query("orders")
      expect(query).to include("query($first: Int!, $after: String)")
    end

    it "includes orders field definitions in orders query" do
      query = api_client.gql_query("orders")
      expect(query).to include("orders(")
    end

    it "raises an error for invalid query names" do
      expect {
        api_client.gql_query("invalid")
      }.to raise_error(ArgumentError, "Invalid query name: invalid")
    end
  end
end
