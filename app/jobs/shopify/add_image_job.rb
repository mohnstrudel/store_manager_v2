# frozen_string_literal: true
class Shopify::AddImageJob < ApplicationJob
  def perform(shopify_product_id, product_id)
    product = Product.find(product_id)
    return unless product || product.images.any?

    blobs = product.images.map(&:blob)
    blobs.each { wait_until_file_is_available(it) }

    images_input = blobs.map {
      {
        originalSource: it.url,
        alt: it.key,
        mediaContentType: "IMAGE"
      }
    }

    api_client = Shopify::ApiClient.new
    api_client.add_images(shopify_product_id, images_input)
  end

  def wait_until_file_is_available(blob, timeout: 300)
    Timeout.timeout(timeout) do
      loop do
        break if blob.service.exist?(blob.key)
        sleep 2
      end
    end
  rescue Timeout::Error
    raise "File was not uploaded to R2 in #{timeout} seconds (blob_id: #{blob.id})"
  end
end
