# frozen_string_literal: true

# Pushes local product media to Shopify.
# It attaches new media, updates changed media, reorders the remote product,
# and clears Shopify references if the product no longer exists remotely.
module Product::Shopify::Media
  class Push
    def self.call(product_id:, product_store_id:)
      new(product_id:, product_store_id:).call
    end

    def initialize(product_id:, product_store_id:)
      @product_id = product_id
      @product_store_id = product_store_id
    end

    def call
      product = Product.for_media_sync.find(product_id)
      api_client = Shopify::Api::Client.new

      new_media, existing_media = product.media.partition { |media| media.shopify_info.nil? }
      return unless new_media.any? || existing_media.any?

      if new_media.any?
        Attach.new(
          product:,
          product_store_id:,
          api_client:,
          new_media:
        ).call
      end

      if existing_media.any?
        Update.new(
          product:,
          api_client:,
          existing_media:
        ).call
      end

      Reorder.new(
        product:,
        product_store_id:,
        api_client:
      ).call
    rescue Shopify::Api::Client::ApiError => e
      raise unless e.message.include?("Product does not exist")

      Cleanup.new(product: product).call(e)
    end

    private

    attr_reader :product_id, :product_store_id
  end
end
