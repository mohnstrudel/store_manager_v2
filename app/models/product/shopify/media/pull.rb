# frozen_string_literal: true

# Pulls Shopify media into the local product.
# It either exits early when there is no product or no media, or it downloads
# the remote files, removes obsolete local media, and upserts the downloads.
module Product::Shopify::Media
  class Pull
    def self.call(product_id:, parsed_media:)
      new(product_id:, parsed_media:).call
    end

    def initialize(product_id:, parsed_media:)
      @product_id = product_id
      @parsed_media = parsed_media
    end

    def call
      return if product_id.blank?

      return unless load_product
      return clear_media! if parsed_media.blank?

      media_items = build_media_items
      downloaded_files = download_media_items(media_items)
      remove_obsolete_media(downloaded_files)
      upsert_downloaded_media!(media_items:, downloaded_files:)
    ensure
      downloaded_files&.close_downloads!
    end

    private

    attr_reader :product_id, :parsed_media, :product

    def load_product
      @product = Product.for_media_sync.find_by(id: product_id)
    end

    def clear_media!
      product.media.destroy_all
    end

    def build_media_items
      parsed_media.each_with_index.map do |payload, index|
        {
          key: payload[:id].presence || payload[:url].presence || "media:#{index}",
          payload: payload,
          store_id: payload[:id],
          url: payload[:url]
        }
      end
    end

    def download_media_items(media_items)
      Downloader.call(media_items:)
    end

    def remove_obsolete_media(downloaded_files)
      return if downloaded_files.downloaded_checksums.blank?

      obsolete_media_for(downloaded_files).destroy_all
    end

    def obsolete_media_for(downloaded_files)
      media = media_with_outdated_checksums(downloaded_files.downloaded_checksums)
      exclude_failed_download_media(media, downloaded_files.failed_store_ids)
    end

    def media_with_outdated_checksums(downloaded_checksums)
      product.media
        .joins(image_attachment: :blob)
        .where.not(active_storage_blobs: {checksum: downloaded_checksums})
    end

    def exclude_failed_download_media(obsolete_media, failed_store_ids)
      return obsolete_media if failed_store_ids.blank?

      failed_download_media_ids = product.media
        .joins(:store_infos)
        .where(store_infos: {store_name: :shopify, store_id: failed_store_ids})
        .select(:id)

      obsolete_media.where.not(id: failed_download_media_ids)
    end

    def upsert_downloaded_media!(media_items:, downloaded_files:)
      Upsert.new(product:).call(
        media_items:,
        downloads_by_key: downloaded_files.downloads_by_key
      )
    end
  end
end
