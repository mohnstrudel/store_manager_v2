# frozen_string_literal: true

module Sale::Titled
  extend ActiveSupport::Concern

  included do
    scope :for_link_title, -> { includes(:customer, sale_items: [{product: {media: {image_attachment: :blob}}}, :variant]) }
  end

  def title
    [status&.titleize, shop_identifier].compact_blank.join(" | ")
  end

  def shop_identifier
    shopify_name.presence || short_shopify_id(shopify_id) || woo_store_id
  end

  def select_title
    name = customer&.full_name.presence
    email = customer&.email.presence
    woo = woo_store_id.presence
    total = total.present? ? "$#{"%.2f" % total}" : nil
    [name, email, status&.titleize, total, woo].compact.join(" | ")
  end

  def full_title
    [customer&.name_and_email, woo_store_id.presence].compact.join(" | ")
  end

  def link_title
    [shop_identifier.presence || id, customer&.full_name, customer&.email, *sale_items.map(&:title)].compact_blank.join(", ")
  end

  private

  def short_shopify_id(store_id)
    store_id.to_s.split("/").last.presence
  end
end
