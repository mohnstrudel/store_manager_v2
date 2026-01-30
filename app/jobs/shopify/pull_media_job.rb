# frozen_string_literal: true

module Shopify
  class PullMediaJob < ApplicationJob
    attr_reader :product
    private :product

    SHOPIFY_STORE_NAME = "shopify"
    MAX_FILE_SIZE = 20 * 1024 * 1024 # 20MB

    DownloadedImage = Data.define(:file, :filename, :checksum)

    def perform(product_id, parsed_media)
      return if product_id.blank?

      @product = Product
        .includes(
          media: [
            :image_attachment,
            :image_blob,
            :shopify_info
          ]
        )
        .find(product_id)

      return if product.blank?

      if parsed_media.blank?
        product.media.destroy_all
        return
      end

      downloaded = download_all_media(parsed_media)
      remove_obsolete_media(downloaded.values.map(&:checksum))

      media_syncer = MediaSyncer.new(product, existing_media_by_checksum)

      parsed_media.each do |parsed_item|
        downloaded_file = downloaded[parsed_item]
        next unless downloaded_file

        media_syncer.sync(parsed_item, downloaded_file)
      end
    ensure
      cleanup_downloaded_files(downloaded) if defined?(downloaded)
    end

    private

    def download_all_media(parsed_media)
      parsed_media.index_with do |item|
        download_image(item[:url]) if item[:url].present?
      end.compact
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
      Rails.logger.error "[PullMediaJob] Download failed #{url} – #{e.class}: #{e.message}"
      nil
    end

    def remove_obsolete_media(downloaded_checksums)
      return if downloaded_checksums.blank?

      product.media
        .joins(image_attachment: :blob)
        .where.not(active_storage_blobs: {checksum: downloaded_checksums})
        .destroy_all
    end

    def existing_media_by_checksum
      product.media
        .joins(image_attachment: :blob)
        .index_by { |media| media.image.blob.checksum }
    end

    def cleanup_downloaded_files(downloaded)
      downloaded&.each_value { |downloaded| downloaded.file.close }
    end

    class MediaSyncer
      attr_reader :product, :existing_by_checksum, :parsed_item, :downloaded_file
      private :product, :existing_by_checksum, :parsed_item, :downloaded_file

      def initialize(product, existing_by_checksum)
        @product = product
        @existing_by_checksum = existing_by_checksum
      end

      def sync(parsed_item, downloaded_file)
        @parsed_item = parsed_item
        @downloaded_file = downloaded_file

        media = find_or_build_media

        update_media_attributes(media)
        update_or_create_shopify_info(media)
        attach_image(media) unless media.image.attached?
      end

      private

      def find_or_build_media
        if (existing = existing_by_checksum[downloaded_file.checksum])
          existing
        else
          product.media.build
        end
      end

      def update_media_attributes(media)
        media.update!(
          alt: parsed_item[:alt],
          position: parsed_item[:position]
        )
      end

      def attach_image(media)
        media.image.attach(
          io: downloaded_file.file,
          filename: downloaded_file.filename
        )
      end

      def update_or_create_shopify_info(media)
        attrs = shopify_info_attributes(media)

        if media.shopify_info&.persisted?
          media.shopify_info.update!(attrs)
        else
          media.store_infos.create!(attrs)
        end
      end

      def shopify_info_attributes(media)
        {
          storable: media,
          store_name: SHOPIFY_STORE_NAME,
          store_id: parsed_item[:id],
          checksum: downloaded_file.checksum,
          pull_time: Time.zone.now,
          ext_created_at: Time.zone.parse(parsed_item.dig(:store_info, :ext_created_at)),
          ext_updated_at: Time.zone.parse(parsed_item.dig(:store_info, :ext_updated_at))
        }
      end
    end
  end
end
