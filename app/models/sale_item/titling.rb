# frozen_string_literal: true

module SaleItem::Titling
  extend ActiveSupport::Concern

  def title
    edition_id.present? ? "#{product.full_title} → #{edition.title}" : product.full_title
  end

  def build_title_for_select
    status = sale.status&.titleize
    email = sale.customer.email
    pretty_sale_id = "Sale ID: #{sale_id}"
    pretty_woo_id = woo_id && "Woo ID: #{woo_id}"

    [id, status, title, email, pretty_sale_id, pretty_woo_id].compact.join(" | ")
  end
end
