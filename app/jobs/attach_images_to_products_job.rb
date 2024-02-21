class AttachImagesToProductsJob < ApplicationJob
  queue_as :default
  workers 5

  def perform
    product_job = SyncWooProductsJob.new
    parsed_products = product_job.parse_all(product_job.get_woo_products)
    products = Product.where(woo_id: parsed_products.pluck(:woo_id))

    products.each do |product|
      parsed_product = parsed_products.find do |parsed_product|
        parsed_product[:woo_id].to_s == product.woo_id
      end
      next unless parsed_product
      parsed_product[:images].each do |img_url|
        attach_images(product, img_url) if img_url
      end
    end
  end

  def attach_images(product, img_url)
    uri = URI.parse(img_url)
    filename = File.basename(uri.path)
    return if product.images.any? { |i| i.filename == filename }

    retries = 0
    io = begin
      uri.open
    rescue OpenURI::HTTPError => e
      retries += 1
      if retries < 3
        sleep 5
        retry
      else
        Rails.logger.error "AttachImagesToProductsJob. Failed to download an image #{img_url}: #{e.message}"
        nil
      end
    end
    return unless io

    product.images.attach(io:, filename:)
  end
end
