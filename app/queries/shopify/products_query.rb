# frozen_string_literal: true

module Shopify
  class ProductsQuery
    class << self
      def for_media_sync(scope = Product.all)
        scope.includes(media: [:image_attachment, :image_blob, :shopify_info])
      end
    end
  end
end
