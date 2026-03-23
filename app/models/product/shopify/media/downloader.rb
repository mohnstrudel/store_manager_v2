# frozen_string_literal: true

# Downloads the remote media files one by one.
# It skips blank URLs, keeps successful downloads, and remembers which Shopify
# store IDs failed so the caller can avoid deleting matching local media.
module Product::Shopify::Media
  class Downloader
    MAX_FILE_SIZE = 20 * 1024 * 1024 # 20MB
    DownloadedImage = Data.define(:file, :filename, :checksum)

    attr_reader :downloads_by_key, :failed_store_ids

    def self.call(media_items:)
      new(media_items:).call
    end

    def initialize(media_items:)
      @media_items = media_items
      @downloads_by_key = {}
      @failed_store_ids = []
    end

    def call
      media_items.each do |item|
        process_item(item)
      end

      self
    end

    def downloaded_checksums
      downloads_by_key.values.map(&:checksum)
    end

    def close_downloads!
      downloads_by_key.each_value { |downloaded| downloaded.file.close }
    end

    private

    attr_reader :media_items

    def process_item(item)
      return if item[:url].blank?

      downloaded_file = download_image(item[:url])
      return record_failed_download(item) unless downloaded_file

      store_download(item, downloaded_file)
    end

    def record_failed_download(item)
      record_failed_store_id(item[:store_id])
    end

    def store_download(item, downloaded_file)
      downloads_by_key[item[:key]] = downloaded_file
    end

    def download_image(url)
      file = Down.download(
        url,
        max_size: MAX_FILE_SIZE,
        open_timeout: 5,
        read_timeout: 15
      )

      checksum = Digest::MD5.file(file.path).base64digest
      filename = File.basename(file.original_filename || url)

      DownloadedImage.new(file:, filename:, checksum:)
    rescue Down::Error => e
      Rails.logger.error "[Product::Shopify::Media::Pull] Download failed #{url} - #{e.class}: #{e.message}"
      nil
    end

    def record_failed_store_id(store_id)
      return if store_id.blank?
      return if failed_store_ids.include?(store_id)

      failed_store_ids << store_id
    end
  end
end
