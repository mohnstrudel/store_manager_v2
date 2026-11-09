# frozen_string_literal: true

module Helpers
  module ShopifyMediaScenarios
    def cdn_url(name, version: 1)
      "https://cdn.example.com/files/#{name}.jpg?v=#{version}"
    end

    def image_checksum(bytes)
      Digest::MD5.base64digest(bytes)
    end

    def pulled_media(bytes, number: nil, source_url: nil, alt: "", position: 0, alt_text: alt)
      media = product.media.create!(
        alt:,
        position:,
        image: {io: StringIO.new(bytes), filename: "pulled.jpg", content_type: "image/jpeg"}
      )
      return media unless number

      link_media(media, number, source_url:, alt_text:)
    end

    def link_media(media, number, source_url: nil, alt_text: media.alt)
      media.store_infos.create!(
        store_name: :shopify,
        store_id: media_gid(number),
        source_url:,
        alt_text:,
        checksum: media.image.blob.checksum,
        pull_time: 1.day.ago
      )
      media
    end

    def media_gid(number)
      "gid://shopify/MediaImage/#{number}"
    end

    def media_node(number, name: number, version: 1, url: cdn_url(name, version:), alt: "", position: 0)
      {key: media_gid(number), id: media_gid(number), url:, alt:, position:}
    end

    def non_image_node(position)
      {key: "media:#{position}", id: nil, url: nil, alt: nil, position:}
    end
  end
end
