# frozen_string_literal: true

module Sale::Titling
  extend ActiveSupport::Concern

  def title
    [status&.titleize, shop_identifier].compact_blank.join(" | ")
  end

  def select_title
    name = customer.full_name.presence
    email = customer.email.presence
    woo = woo_store_id.presence
    total = total.present? ? "$#{"%.2f" % total}" : nil
    [name, email, status&.titleize, total, woo].compact.join(" | ")
  end

  def full_title
    [customer.name_and_email, woo_store_id.presence].compact.join(" | ")
  end

  def shop_identifier
    shopify_name.presence || short_shopify_id(shopify_id) || woo_store_id
  end

  private

  def short_shopify_id(store_id)
    store_id.to_s.split("/").last.presence
  end
end
