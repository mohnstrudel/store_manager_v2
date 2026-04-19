# frozen_string_literal: true

module Product::Shopify::MediaImporting
  def import_shopify_media!(parsed_media:)
    return media.destroy_all if parsed_media.blank?

    downloaded_files = Product::Shopify::Media::Downloader.call(media_items: parsed_media)
    remove_obsolete_shopify_media(downloaded_files)
    upsert_shopify_media!(media_items: parsed_media, downloaded_files:)
  ensure
    downloaded_files&.close_downloads!
  end

  private

  def remove_obsolete_shopify_media(downloaded_files)
    return if downloaded_files.downloaded_checksums.blank?

    obsolete_shopify_media_for(downloaded_files).destroy_all
  end

  def obsolete_shopify_media_for(downloaded_files)
    obsolete_media = media_with_outdated_checksums(downloaded_files.downloaded_checksums)
    exclude_failed_download_media(obsolete_media, downloaded_files.failed_store_ids)
  end

  def media_with_outdated_checksums(downloaded_checksums)
    media
      .joins(image_attachment: :blob)
      .where.not(active_storage_blobs: {checksum: downloaded_checksums})
  end

  def exclude_failed_download_media(obsolete_media, failed_store_ids)
    return obsolete_media if failed_store_ids.blank?

    failed_download_media_ids = media
      .joins(:store_infos)
      .where(store_infos: {store_name: :shopify, store_id: failed_store_ids})
      .select(:id)

    obsolete_media.where.not(id: failed_download_media_ids)
  end

  def upsert_shopify_media!(media_items:, downloaded_files:)
    Product::Shopify::Media::Upsert.new(product: self).call(
      media_items:,
      downloads_by_key: downloaded_files.downloads_by_key
    )
  end
end
