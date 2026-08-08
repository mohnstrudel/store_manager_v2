# frozen_string_literal: true

module Shopify
  class MediaIntegritySweepJob < ApplicationJob
    queue_as :default

    BATCH_SIZE = 500

    def perform
      healed_product_ids = Set.new

      Media.where(mediaable_type: "Product")
        .joins(image_attachment: :blob)
        .in_batches(of: BATCH_SIZE) do |batch|
          batch.preload(:mediaable, image_attachment: {blob: :variant_records}).find_each do |media|
            heal_media(media, healed_product_ids)
          end
        end
    end

    private

    def heal_media(media, healed_product_ids)
      blob = media.image.blob

      if blob.service.exist?(blob.key)
        heal_variants(blob)
      else
        enqueue_pull_product(media.mediaable, healed_product_ids)
      end
    rescue => e
      Rails.logger.warn(
        "[Shopify::MediaIntegritySweepJob] Skipping media=#{media.id}: #{e.class}: #{e.message}"
      )
    end

    def heal_variants(blob)
      blob.variant_records.each do |variant_record|
        next unless variant_record.image.attached?

        variant_blob = variant_record.image.blob
        variant_record.destroy! unless variant_blob.service.exist?(variant_blob.key)
      end
    end

    def enqueue_pull_product(product, healed_product_ids)
      shopify_store_id = product.shopify_store_id
      return if shopify_store_id.blank?
      return unless healed_product_ids.add?(product.id)

      Shopify::PullProductJob.perform_later(shopify_store_id)
    end
  end
end
