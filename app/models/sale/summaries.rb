# frozen_string_literal: true

module Sale::Summaries
  extend ActiveSupport::Concern

  def title
    shop_id = if shopify_id.present?
      shopify_name
    else
      woo_id
    end
    [status&.titleize, shop_id].compact.join(" | ")
  end

  def select_title
    name = customer.full_name.presence
    email = customer.email.presence
    woo = woo_id.presence
    total = total.presence || 0
    [name, email, status&.titleize, "$#{"%.2f" % total}", woo].compact.join(" | ")
  end

  def created
    woo_created_at || created_at
  end

  def full_title
    [customer.name_and_email, woo_id.presence].compact.join(" | ")
  end
end
