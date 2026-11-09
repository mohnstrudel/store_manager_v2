# frozen_string_literal: true

module Product::Shopify::Media
  class Push
    Snapshot = Data.define(:new_media, :existing_media, :nodes) do
      def attached?
        new_media.any?
      end
    end
    private_constant :Snapshot

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

      snapshot = product.with_lock { attach_new_media(product, api_client) }
      return if snapshot.nil?

      raise NotReady, "Attached #{snapshot.new_media.size} image(s) to #{product_store_id}" if snapshot.attached?

      ensure_ready(snapshot.nodes)
      Update.new(product:, api_client:, existing_media: snapshot.existing_media).call
      Reorder.new(product:, product_store_id:, api_client:, nodes: snapshot.nodes).call
    rescue Shopify::Api::Client::ApiError => e
      raise unless e.message.include?("Product does not exist")

      Cleanup.new(product: product).call(e)
    end

    private

    attr_reader :product_id, :product_store_id

    def attach_new_media(product, api_client)
      media = product.media.with_attached_image.includes(:shopify_info).to_a
      return if media.empty?

      new_media, existing_media = media.partition { |item| item.shopify_info.nil? }

      self.class.ensure_files_stored(new_media)
      nodes = fetch_nodes(api_client)
      known_ids = nodes.filter_map { |node| node["id"] }

      if new_media.any?
        Attach.new(product:, product_store_id:, api_client:, new_media:, known_ids:).call
      end

      Snapshot.new(new_media:, existing_media:, nodes:)
    end

    def fetch_nodes(api_client)
      payload = api_client.fetch_product(product_store_id)
      raise Shopify::Api::Client::ApiError, "Failed to fetch product: Product does not exist" if payload.nil?

      payload["media"]["nodes"]
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
