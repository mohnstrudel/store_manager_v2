# frozen_string_literal: true

module GalleryHelper
  def gallery_items_for(media)
    media.filter_map do |media_item|
      next unless media_item.image.attached?

      {
        alt: media_item.alt.presence || media_item.try(:title).presence || "Gallery image",
        main_src: url_for(media_item.image.representation(:preview)),
        thumb_src: url_for(media_item.image.representation(:nano))
      }
    end
  end
end
