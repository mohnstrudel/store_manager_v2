class Shopify::AddImageJob < ApplicationJob
  def perform(shopify_product_id, blob_id)
    blob = ActiveStorage::Blob.find(blob_id)
    return unless blob

    wait_until_file_is_available(blob)

    api_client = Shopify::ApiClient.new
    api_client.productUpdate(shopify_product_id, blob.url)
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
