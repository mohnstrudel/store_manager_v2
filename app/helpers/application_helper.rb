# frozen_string_literal: true

module ApplicationHelper
  def pagination_props(collection)
    {
      current_page: collection.current_page,
      total_pages: collection.total_pages,
      total_count: collection.total_count,
      limit: collection.limit_value
    }
  end

  def media_props(media)
    return unless media.image.attached?

    {
      id: media.id,
      alt: media.alt,
      position: media.position,
      preview_url: url_for(media.image.representation(:preview)),
      thumb_url: url_for(media.image.representation(:thumb))
    }
  end
end
