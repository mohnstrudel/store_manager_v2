# frozen_string_literal: true

require "open-uri"

module Shopify
  class PullMediaJob < ApplicationJob
    queue_as :default

    def perform(product, parsed_media)
      return if product.blank? || parsed_media.blank?

      parsed_media.each do |pm|
        media_store_info = StoreInfo.find_by(store_id: pm[:id])

        if media_store_info.present?
          update_existing_media(pm, media_store_info)
        else
          create_or_link_media(pm, product)
        end
      end
    end

    def update_existing_media(parsed_media, store_info)
      ActiveRecord::Base.transaction do
        media = store_info.storable
        media.update!(alt: parsed_media[:alt], position: parsed_media[:position])

        pull_time = Time.zone.parse(parsed_media[:updated_at])
        next if store_info.pull_time.blank? || pull_time == store_info.pull_time

        attach_image(media, parsed_media[:url])
        store_info.update!(pull_time:)
      end
    end

    def create_or_link_media(parsed_media, product)
      ActiveRecord::Base.transaction do
        uploaded_file = uploaded_file_data(parsed_media[:url])
        return unless uploaded_file

        io, filename = uploaded_file
        checksum = Digest::MD5.file(io).base64digest

        media = product.media
          .joins(image_attachment: :blob)
          .find_by(active_storage_blobs: {checksum:})

        if media
          media.update!(alt: parsed_media[:alt], position: parsed_media[:position])
        else
          media = product.media.create!(alt: parsed_media[:alt], position: parsed_media[:position])
          media.image.attach(io:, filename:)
        end

        media.store_infos.create!(
          store_id: parsed_media[:id],
          store_name: :shopify,
          pull_time: Time.zone.parse(parsed_media[:updated_at])
        )
      end
    end

    def attach_image(media, img_url)
      uploaded_file = uploaded_file_data(img_url)
      return unless uploaded_file

      io, filename = uploaded_file
      media.image.attach(io:, filename:)
    end

    def uploaded_file_data(img_url)
      uri = parse_uri(img_url)
      return unless uri

      io = download_with_retry(uri, img_url)
      return unless io

      [io, File.basename(uri.path)]
    end

    def parse_uri(img_url)
      URI.parse(img_url)
    rescue URI::InvalidURIError
      begin
        URI.parse(URI::DEFAULT_PARSER.escape(img_url))
      rescue URI::InvalidURIError
        nil
      end
    end

    def download_with_retry(uri, img_url)
      retries = 0

      begin
        uri.open
      rescue OpenURI::HTTPError => e
        retries += 1
        if retries < 3
          sleep 5
          retry
        else
          Rails.logger.error "ShopifyPullMediaJob. Failed to download an image #{img_url}: #{e.message}"
          nil
        end
      end
    end
  end
end
