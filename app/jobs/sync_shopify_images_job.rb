class SyncShopifyImagesJob < ApplicationJob
  queue_as :default

  def perform(product, parsed_images)
    return if product.blank? || parsed_images.blank?

    progressbar = ProgressBar.create(
      title: "#{self.class.name} for #{product.title} (#{parsed_images.size} images): ",
      total: parsed_images.size
    )

    parsed_images.each do |image_data|
      attach_image(product, image_data["src"])
      progressbar.increment
    end
  end

  private

  def attach_image(product, img_url)
    retries = 0

    uri = begin
      URI.parse(img_url)
    rescue URI::InvalidURIError => e
      URI.parse(URI::DEFAULT_PARSER.escape(img_url))
    end

    filename = File.basename(uri.path)

    io = begin
      uri.open
    rescue OpenURI::HTTPError => e
      retries += 1
      if retries < 3
        sleep 5
        retry
      else
        Rails.logger.error "SyncShopifyImagesJob. Failed to download an image #{img_url}: #{e.message}"
        nil
      end
    end

    return unless io

    checksum = Digest::MD5.file(io).base64digest
    existing_image = product.images.find_by(checksum: checksum)

    product.images.attach(io:, filename:) unless existing_image
  end
end
