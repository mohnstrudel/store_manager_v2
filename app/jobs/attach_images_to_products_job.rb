class AttachImagesToProductsJob < ApplicationJob
  queue_as :low_priority
  workers 3

  def perform(product, img_url)
    uri = URI.parse(img_url)
    product.images.attach(io: uri.open, filename: File.basename(uri.path))
  rescue OpenURI::HTTPError => e
    Rails.logger.error "AttachImagesJob. Failed to open URI: #{e.message}"
    nil
  rescue URI::InvalidURIError => e
    Rails.logger.error "AttachImagesJob. Invalid URI: #{e.message}"
    nil
  rescue => e
    Rails.logger.error "AttachImagesJob. Failed to attach image #{img_url}: #{e.message}"
    nil
  end
end
