class AttachImagesToProductsJob < ApplicationJob
  queue_as :default

  def perform
    product_job = SyncWooProductsJob.new
    parsed_products = product_job.parse_all(product_job.get_woo_products)
    products = Product.where(woo_id: parsed_products.pluck(:woo_id))

    total = parsed_products.pluck(:images).flatten.size
    progressbar = ProgressBar.create(
      title: self.class.name + "(#{total} total): ",
      total:
    )

    products.each do |product|
      parsed_product = parsed_products.find do |parsed_product|
        parsed_product[:woo_id].to_s == product.woo_id
      end

      next unless parsed_product

      parsed_product[:images].each do |img_url|
        attach_images(product, img_url) if img_url
        progressbar.increment
      end
    end
  end

  def attach_images(product, img_url)
    retries = 0

    uri = begin
      URI.parse(img_url)
    rescue URI::InvalidURIError => e
      URI.parse(URI::DEFAULT_PARSER.escape(img_url))
    end

    filename = File.basename(uri.path)

    return if product.media.any? { |i| i.filename == filename }

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

    media = product.media.create
    media.image.attach(io:, filename:)
  end
end
