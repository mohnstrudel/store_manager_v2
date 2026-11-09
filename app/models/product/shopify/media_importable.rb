# frozen_string_literal: true

module Product::Shopify::MediaImportable
  def import_shopify_media(parsed_media:, force: false)
    return media.destroy_all if parsed_media.blank?

    upsert = Product::Shopify::Media::Upsert.new(product: self, media_items: parsed_media, force:)
    items_to_download = upsert.media_items_to_download
    downloaded_files = Product::Shopify::Media::Downloader.call(media_items: items_to_download)
    upsert.call(downloads_by_key: downloaded_files.downloads_by_key)
    remove_obsolete_shopify_media(parsed_media:, items_to_download:, downloaded_files:)
  ensure
    downloaded_files&.close_downloads
  end

  private

  def remove_obsolete_shopify_media(parsed_media:, items_to_download:, downloaded_files:)
    return if items_to_download.any? && downloaded_files.downloads_by_key.empty?

    obsolete_shopify_media(
      store_ids: parsed_media.filter_map { |item| item[:id].presence },
      downloaded_checksums: downloaded_files.downloaded_checksums
    ).destroy_all
  end

  def obsolete_shopify_media(store_ids:, downloaded_checksums:)
    store_info = StoreInfo.arel_table

    media
      .joins(image_attachment: :blob)
      .left_joins(:shopify_info)
      .where(store_info[:store_id].eq(nil).or(store_info[:store_id].not_in(store_ids)))
      .where.not(active_storage_blobs: {checksum: downloaded_checksums})
  end
end
