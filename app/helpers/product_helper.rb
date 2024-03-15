module ProductHelper
  def format_relation(relationship, key)
    return "-" if relationship.blank?
    relationship.pluck(key).join(", ")
  end

  def product_thumb_url(product)
    if product.images.present?
      url_for(product.images.first.representation(:thumb))
    end
  end
end
