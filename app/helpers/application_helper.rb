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

  def purchase_display_product(purchase)
    purchase&.product || purchase&.variant&.product
  end

  def purchase_product_path(purchase)
    product = purchase_display_product(purchase)
    product ? product_path(product) : nil
  end

  def purchase_product_title(purchase)
    purchase_display_product(purchase)&.full_title || "Unknown product"
  end

  def purchase_product_image_url(purchase)
    purchase_display_product(purchase)&.image.presence
  end

  def purchase_product_thumb_url(purchase)
    product = purchase_display_product(purchase)
    return unless product

    thumb_url(product)
  end
end
