# frozen_string_literal: true

class Product::Shopify::Media::Push::Reorder
  def initialize(product:, product_store_id:, api_client:)
    @product = product
    @product_store_id = product_store_id
    @api_client = api_client
  end

  def call
    media = product.media.ordered.preload(:store_infos)
    api_product_response = api_client.fetch_product(product_store_id)

    shopify_positions = api_product_response["media"]["nodes"]
      .each_with_index
      .to_h { |node, index| [node["id"], index] }

    moves = position_changes(shopify_positions, media)
    return if moves.blank?

    api_client.reorder_media(product_store_id, moves)
  end

  private

  attr_reader :product, :product_store_id, :api_client

  def position_changes(shopify_positions, media)
    media.each_with_index.filter_map do |media_item, our_position|
      next unless (shopify_info = media_item.shopify_info)

      store_id = shopify_info.store_id
      shopify_position = shopify_positions[store_id]

      next if shopify_position == our_position

      {
        id: store_id,
        newPosition: our_position.to_s
      }
    end
  end
end
