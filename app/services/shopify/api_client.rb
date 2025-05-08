require "forwardable"

class Shopify::ApiClient
  extend Forwardable
  def_delegators :@client, :query

  def initialize(limit = nil)
    session = ShopifyAPI::Auth::Session.new(
      shop: ENV.fetch("SHOPIFY_DOMAIN"),
      access_token: ENV.fetch("SHOPIFY_API_TOKEN")
    )
    @client = ShopifyAPI::Clients::Graphql::Admin.new(session:)
  end
end
