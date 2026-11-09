# frozen_string_literal: true

class Products::SaleItemResource < Products::SoldItemResource
  typelize :string
  attribute :country do |sale_item|
    sale_item.sale.shipping_address&.country.presence || ""
  end

  typelize :string, nullable: true
  attribute :price do |sale_item|
    format_money(price(sale_item))
  end

  typelize :string, nullable: true
  attribute :price_original do |sale_item|
    sale = sale_item.sale
    format_money(sale.shop_currency_amount(price(sale_item)), sale.shop_currency)
  end

  def price(sale_item)
    sale_item.sale.projected_item_price || sale_item.price
  end
end
