# frozen_string_literal: true

class Sale::Shopify::OrderId
  GID_PREFIX = "gid://shopify/Order/"

  def self.find_sale(value)
    normalized = normalize(value)
    return if normalized.blank?

    Sale.find_by_shopify_id("#{GID_PREFIX}#{normalized}") || Sale.find_by_shopify_id(normalized)
  end

  def self.normalize(value)
    candidate = value.to_s.strip.delete_prefix(GID_PREFIX)
    candidate if candidate.match?(/\A\d+\z/)
  end
end
