# frozen_string_literal: true

require "zlib"

module Product::Shopify::Media
  class Push
    class NotReady < StandardError; end

    class MediaFailed < StandardError; end

    class AttachMismatch < StandardError; end

    def self.call(product_id:, product_store_id:)
      new(product_id:, product_store_id:).call
    end

    def self.ensure_files_stored(media)
      missing = media.reject { |item| item.image.blob.service.exist?(item.image.blob.key) }
      return if missing.empty?

      raise NotReady, "Files for media #{missing.map(&:id).join(", ")} are not in storage yet"
    end

    def initialize(product_id:, product_store_id:)
      @product_id = product_id
      @product_store_id = product_store_id
    end

    def call
      product = Product.find(product_id)
      api_client = Shopify::Api::Client.new
      media = load_media(product)
      return if media.empty?

      attach_new_media(product, api_client, media.select { |item| item.shopify_info.nil? })

      nodes = fetch_nodes(api_client)
      ensure_ready(nodes)
      Update.new(product:, api_client:, existing_media: media.select(&:shopify_info)).call
      Reorder.new(product:, product_store_id:, api_client:, nodes:).call
    rescue Shopify::Api::Client::ApiError => e
      raise unless e.message.include?("Product does not exist")

      Cleanup.new(product: product).call(e)
    end

    private

    attr_reader :product_id, :product_store_id

    def load_media(product)
      product.media.with_attached_image.includes(:shopify_info).to_a
    end

    def attach_new_media(product, api_client, pending)
      return if pending.empty?

      self.class.ensure_files_stored(pending)
      linked = serialized_per_product { link_new_media(product, api_client, pending.map(&:id)) }
      raise NotReady, "Linked #{linked} image(s) to #{product_store_id}" if linked.positive?
    end

    def serialized_per_product
      ActiveRecord::Base.transaction do
        ActiveRecord::Base.lease_connection.execute("SELECT pg_advisory_xact_lock(#{Zlib.crc32("#{self.class.name}:#{product_id}")})")
        yield
      end
    end

    def link_new_media(product, api_client, verified_ids)
      media = load_media(product)
      new_media = media.select { |item| item.shopify_info.nil? && verified_ids.include?(item.id) }
      return 0 if new_media.empty?

      Attach.new(
        product:, product_store_id:, api_client:, new_media:,
        nodes: fetch_nodes(api_client),
        claimed_ids: media.filter_map { |item| item.shopify_info&.store_id }
      ).call
    end

    def fetch_nodes(api_client)
      nodes = api_client.fetch_product_media(product_store_id)
      raise Shopify::Api::Client::ApiError, "Failed to fetch product: Product does not exist" if nodes.nil?

      nodes
    end

    def ensure_ready(nodes)
      image_nodes = nodes.select { |node| node["id"].present? }

      failed = image_nodes.select { |node| node["status"] == "FAILED" }
      raise MediaFailed, "Shopify failed to process media #{failed.pluck("id").join(", ")} of #{product_store_id}" if failed.any?

      unready = image_nodes.reject { |node| node["status"] == "READY" }
      raise NotReady, "Shopify has not finished processing media #{unready.pluck("id").join(", ")} of #{product_store_id}" if unready.any?
    end
  end
end
