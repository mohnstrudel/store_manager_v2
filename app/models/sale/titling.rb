# frozen_string_literal: true

module Sale::Titling
  extend ActiveSupport::Concern

  def title
    shop_id = if shopify_id.present?
      shopify_name
    else
      woo_id
    end
    [status&.titleize, shop_id].compact_blank.join(" | ")
  end

  def select_title
    name = customer.full_name.presence
    email = customer.email.presence
    woo = woo_id.presence
    total = total.present? ? "$#{"%.2f" % total}" : nil
    [name, email, status&.titleize, total, woo].compact.join(" | ")
  end

  def full_title
    [customer.name_and_email, woo_id.presence].compact.join(" | ")
  end
end
