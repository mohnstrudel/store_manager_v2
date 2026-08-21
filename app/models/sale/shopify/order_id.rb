# frozen_string_literal: true

class Sale::Shopify::OrderId
  GID_PREFIX = "gid://shopify/Order/"

  def self.normalize(value)
    candidate = value.to_s.strip
    return if candidate.blank?
    return candidate if candidate.match?(/\A\d+\z/)
    return candidate.delete_prefix(GID_PREFIX) if candidate.match?(/\A#{Regexp.escape(GID_PREFIX)}\d+\z/)
  end

  def self.find_sale(value)
    normalized = normalize(value)
    return if normalized.blank?

    StoreInfo
      .shopify
      .find_by(
        storable_type: "Sale",
        store_id: [normalized, "#{GID_PREFIX}#{normalized}"]
      )
      &.storable
  end

  private_class_method :new
end
