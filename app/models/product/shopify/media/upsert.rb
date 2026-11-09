# frozen_string_literal: true

module Product::Shopify::Media
  class Upsert
    SHOPIFY_STORE_NAME = "shopify"

    def initialize(product:, media_items:, force: false)
      @product = product
      @media_items = media_items
      @force = force
      @pulled_at = Time.zone.now
      @unchanged_store_info_ids = []
    end

    def media_items_to_download
      media_items.select { |item| download?(item, matched_row(item)) }
    end

    def call(downloads_by_key:)
      detach_duplicate_rows
      media_items.each { |item| upsert_item(item, downloads_by_key) }
      refresh_unchanged_pull_times
    end

    private

    attr_reader :product, :media_items, :force, :pulled_at, :unchanged_store_info_ids

    def download?(item, row)
      return false if item[:url].blank?

      row.nil? || force || !row.image.attached? || url_changed?(row, item)
    end

    def url_changed?(row, item)
      source_url = row.shopify_info.source_url
      source_url.present? && source_url != item[:url]
    end

    def matched_row(item)
      claimants_by_store_id[item[:id]]&.first
    end

    def claimants_by_store_id
      @claimants_by_store_id ||= rows
        .select { |row| payload_store_ids.include?(row.shopify_store_id) }
        .group_by(&:shopify_store_id)
        .transform_values { |claimants| claimants.sort_by { |row| row.shopify_info.id } }
    end

    def rows
      @rows ||= product.media.includes(:shopify_info, image_attachment: :blob).to_a
    end

    def payload_store_ids
      @payload_store_ids ||= media_items.filter_map { |item| item[:id].presence }.to_set
    end

    def detach_duplicate_rows
      duplicate_rows.each do |row|
        row.shopify_info.destroy!
        row.association(:shopify_info).reset
      end
    end

    def duplicate_rows
      claimants_by_store_id.values.flat_map { |claimants| claimants.drop(1) }
    end

    def upsert_item(item, downloads_by_key)
      row = matched_row(item)

      if download?(item, row)
        download = downloads_by_key[item[:key]]
        upsert_download(row, item, download) if download
      elsif row
        sync_without_download(row, item)
      end
    end

    def upsert_download(row, item, download)
      row ||= linkable_row(download)

      if row
        reconcile(row, item, download)
      else
        create_row(item, download)
      end
    end

    def linkable_row(download)
      unlinked_rows_by_checksum[download.checksum]&.shift
    end

    def unlinked_rows_by_checksum
      @unlinked_rows_by_checksum ||= unclaimed_rows
        .select { |row| row.image.attached? }
        .group_by { |row| row.image.blob.checksum }
    end

    def unclaimed_rows
      rows - claimants_by_store_id.values.map(&:first)
    end

    def reconcile(row, item, download)
      update_media_row(row, item)
      attach_image(row, download) if replace_image?(row, download)
      save_store_info(row, item, download)
    end

    def update_media_row(row, item)
      row.assign_attributes(alt: item[:alt], position: item[:position])
      row.save! if row.changed?
    end

    def replace_image?(row, download)
      return true unless row.image.attached?

      row.image.blob.checksum != download.checksum || (force && missing_from_storage?(row))
    end

    def missing_from_storage?(row)
      blob = row.image.blob
      !blob.service.exist?(blob.key)
    rescue => e
      Rails.logger.warn(
        "[Product::Shopify::Media::Upsert] Falling back to reattach missing image " \
        "for media=#{row.id}: #{e.class}: #{e.message}"
      )
      true
    end

    def attach_image(row, download)
      row.image.attach(io: download.file, filename: download.filename)
    end

    def save_store_info(row, item, download)
      info = row.shopify_info || row.store_infos.build(store_name: SHOPIFY_STORE_NAME)
      info.update!(
        store_id: item[:id],
        source_url: item[:url],
        checksum: download.checksum,
        alt_text: item[:alt],
        pull_time: pulled_at
      )
    end

    def create_row(item, download)
      row = product.media.create!(
        alt: item[:alt],
        position: item[:position],
        image: {io: download.file, filename: download.filename}
      )
      save_store_info(row, item, download)
    end

    def sync_without_download(row, item)
      update_media_row(row, item)
      info = row.shopify_info
      info.alt_text = item[:alt]
      info.source_url = item[:url] if item[:url].present?

      if info.changed?
        info.pull_time = pulled_at
        info.save!
      else
        unchanged_store_info_ids << info.id
      end
    end

    def refresh_unchanged_pull_times
      return if unchanged_store_info_ids.empty?

      StoreInfo.where(id: unchanged_store_info_ids).update_all(pull_time: pulled_at) # rubocop:disable Rails/SkipsModelValidations -- one statement stamps every unchanged row; per-row saves would add per-row queries
    end
  end
end
