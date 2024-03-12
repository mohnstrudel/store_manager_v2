module ProductHelper
  def format_relation(relationship, key)
    return "-" if relationship.blank?
    relationship.pluck(key).join(", ")
  end

  def product_thumb_url(product)
    if product.images.present?
      product.images.first.representation(:thumb).url
    end
  end
end
