# frozen_string_literal: true

class Product::Shopify::Media::Push::Cleanup
  def initialize(product:)
    @product = product
  end

  def call(error)
    return unless error.message.include?("Product does not exist")

    product.shopify_info.destroy!

    product.media.joins(:store_infos)
      .where(store_infos: {store_name: "shopify"})
      .find_each do |media|
        media.store_infos.where(store_name: "shopify").destroy_all
      end
  end

  private

  attr_reader :product
end
