# frozen_string_literal: true

module Product::Shopify::Media
  class Upsert
    SHOPIFY_STORE_NAME = "shopify"

    def initialize(product:)
      @product = product
    end

    def call(media_items:, downloads_by_key:)
      existing_by_checksum = existing_media_by_checksum

      media_items.each do |item|
        downloaded_file = downloads_by_key[item[:key]]

        if downloaded_file.blank?
          next
        end

        upsert_media(item[:payload], downloaded_file, existing_by_checksum)
      end
    end

    private

    attr_reader :product

    def upsert_media(parsed_item, downloaded_file, existing_by_checksum)
      media = existing_by_checksum[downloaded_file.checksum] || product.media.build
      update_media_attributes(media, parsed_item)
      update_or_create_shopify_info(media, parsed_item, downloaded_file)
      attach_image(media, downloaded_file) if needs_image_attachment?(media)
    end

    def existing_media_by_checksum
      product.media
        .joins(image_attachment: :blob)
        .index_by { |media| media.image.blob.checksum }
    end

    def update_media_attributes(media, parsed_item)
      media.update!(
        alt: parsed_item[:alt],
        position: parsed_item[:position]
      )
    end

    def attach_image(media, downloaded_file)
      media.image.purge if media.image.attached?
      media.image.attach(
        io: downloaded_file.file,
        filename: downloaded_file.filename
      )
    end

    def needs_image_attachment?(media)
      return true unless media.image.attached?

      blob = media.image.blob
      return true if blob.blank?

      !blob.service.exist?(blob.key)
    rescue StandardError => e
      Rails.logger.warn(
        "[Product::Shopify::Media::Upsert] Falling back to reattach missing image " \
        "for media=#{media.id || 'new'}: #{e.class}: #{e.message}"
      )
      true
    end

    def update_or_create_shopify_info(media, parsed_item, downloaded_file)
      attrs = {
        storable: media,
        store_name: SHOPIFY_STORE_NAME,
        store_id: parsed_item[:id],
        checksum: downloaded_file.checksum,
        pull_time: Time.zone.now,
        ext_created_at: parse_timestamp(parsed_item.dig(:store_info, :ext_created_at)),
        ext_updated_at: parse_timestamp(parsed_item.dig(:store_info, :ext_updated_at))
      }

      if media.shopify_info&.persisted?
        media.shopify_info.update!(attrs)
      else
        media.store_infos.create!(attrs)
      end
    end

    def parse_timestamp(value)
      value.present? ? Time.zone.parse(value) : nil
    end
  end
end
