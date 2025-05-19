require "rails_helper"

RSpec.describe Shopify::ApiClient do
  describe "#initialize" do
    before do
      allow(ENV).to receive(:fetch).with("SHOPIFY_DOMAIN").and_return("test-store.myshopify.com")
      allow(ENV).to receive(:fetch).with("SHOPIFY_API_TOKEN").and_return("test-token")
    end

    it "initializes a ShopifyAPI GraphQL client with correct session" do
      session_double = instance_double(ShopifyAPI::Auth::Session)
      client_double = instance_double(ShopifyAPI::Clients::Graphql::Admin)

      expect(ShopifyAPI::Auth::Session).to receive(:new).with(
        shop: "test-store.myshopify.com",
        access_token: "test-token"
      ).and_return(session_double)

      expect(ShopifyAPI::Clients::Graphql::Admin).to receive(:new).with(
        session: session_double
      ).and_return(client_double)

      Shopify::ApiClient.new
    end
  end

  describe "#pull" do
    let(:api_client) { described_class.new }
    let(:graphql_client) { instance_double(ShopifyAPI::Clients::Graphql::Admin) }
    let(:response) do
      instance_double(
        "Response",
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
      expect(graphql_client).to receive(:query).with(
        query: "query { products { edges { node { id } } } }",
        variables: {
          first: 10,
          after: "cursor123"
        }
      )

      api_client.pull(resource_name: "products", cursor: "cursor123", limit: 10)
    end

    it "transforms the response into the expected format" do
      result = api_client.pull(resource_name: "products", cursor: nil, limit: 10)

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
        api_client.pull(resource_name: "", cursor: nil, limit: 10)
      }.to raise_error(ArgumentError, "Name is required")
    end
  end

  describe "#pull_product" do
    let(:api_client) { described_class.new }
    let(:graphql_client) { instance_double(ShopifyAPI::Clients::Graphql::Admin) }
    let(:product_id) { "gid://shopify/Product/123" }
    let(:response) do
      instance_double(
        "Response",
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
      expect(graphql_client).to receive(:query).with(
        query: "query($id: ID!) { product(id: $id) { id title } }",
        variables: {id: product_id}
      )

      api_client.pull_product(product_id)
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
        "Response",
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
      expect(graphql_client).to receive(:query).with(
        query: "query($id: ID!) { order(id: $id) { id name } }",
        variables: {id: order_id}
      )

      api_client.pull_order(order_id)
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

  describe "#gql_query" do
    let(:api_client) { described_class.new }

    before do
      allow(ShopifyAPI::Auth::Session).to receive(:new).and_return(instance_double(ShopifyAPI::Auth::Session))
      allow(ShopifyAPI::Clients::Graphql::Admin).to receive(:new).and_return(instance_double(ShopifyAPI::Clients::Graphql::Admin))
    end

    it "returns the product query when name is 'product'" do
      query = api_client.gql_query("product")
      expect(query).to include("query($id: ID!)")
      expect(query).to include("product(id: $id)")
    end

    it "returns the products query when name is 'products'" do
      query = api_client.gql_query("products")
      expect(query).to include("query($first: Int!, $after: String)")
      expect(query).to include("products(")
    end

    it "returns the order query when name is 'order'" do
      query = api_client.gql_query("order")
      expect(query).to include("query($id: ID!)")
      expect(query).to include("sale(id: $id)")
    end

    it "returns the orders query when name is 'orders'" do
      query = api_client.gql_query("orders")
      expect(query).to include("query($first: Int!, $after: String)")
      expect(query).to include("orders(")
    end

    it "raises an error for invalid query names" do
      expect {
        api_client.gql_query("invalid")
      }.to raise_error(ArgumentError, "Invalid query name: invalid")
    end
  end
end
