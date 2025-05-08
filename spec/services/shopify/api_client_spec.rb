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

    it "delegates query method to the client" do
      client_double = instance_double(ShopifyAPI::Clients::Graphql::Admin)
      allow(ShopifyAPI::Auth::Session).to receive(:new).and_return(instance_double(ShopifyAPI::Auth::Session))
      allow(ShopifyAPI::Clients::Graphql::Admin).to receive(:new).and_return(client_double)

      query = "query { shop { name } }"
      variables = {key: "value"}

      expect(client_double).to receive(:query).with(query: query, variables: variables)

      api_client = Shopify::ApiClient.new
      api_client.query(query: query, variables: variables)
    end
  end
end
