# frozen_string_literal: true

class OutboundEmails::ListingResource < OutboundEmailResource
  typelize :string, nullable: true
  attribute :customer_path do |email|
    customer_path(email.customer_id) if params.fetch(:customer_ids).include?(email.customer_id)
  end

  typelize :string, nullable: true
  attribute :product_thumb_url do |email|
    sale_item = sale_item(email)
    thumb_url(sale_item.product) if sale_item
  end

  typelize :string, nullable: true
  attribute :sale_path do |email|
    sale = sale_item(email)&.sale
    sale_path(sale) if sale
  end

  typelize :string, nullable: true
  attribute :sale_label do |email|
    sale = sale_item(email)&.sale
    "Sale #{sale.shop_identifier.presence || sale.id}" if sale
  end

  typelize :string, nullable: true
  attribute :purchase_path do |email|
    purchase = purchase(email)
    purchase_path(purchase) if purchase
  end

  typelize :string, nullable: true
  attribute :purchase_label do |email|
    purchase = purchase(email)
    "Purchase #{purchase.id}" if purchase
  end

  typelize :string
  attribute :path do |email|
    outbound_email_path(email)
  end

  def sale_item(email)
    params.fetch(:sale_items)[email.sale_item_id]
  end

  def purchase(email)
    params.fetch(:purchase_items)[email.purchase_item_id]&.purchase
  end
end
