# frozen_string_literal: true

module PurchaseProductHelper
  def purchase_product_path(purchase)
    product = purchase_display_product(purchase)
    product ? product_path(product) : nil
  end

  def purchase_display_product(purchase)
    purchase&.product || purchase&.variant&.product
  end

  def purchase_product_title(purchase)
    purchase_display_product(purchase)&.full_title || "Unknown product"
  end

  def purchase_product_image_url(purchase)
    purchase_display_product(purchase)&.image.presence
  end
end
