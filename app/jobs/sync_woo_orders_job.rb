class SyncWooOrdersJob < ApplicationJob
  queue_as :default

  include Gettable

  URL = "https://store.handsomecake.com/wp-json/wc/v3/orders/"
  ORDERS_SIZE = 1800

  def perform
    woo_orders = api_get_all(URL, ORDERS_SIZE)
    parsed_orders = parse_orders(woo_orders)
    create_sales(parsed_orders)
  end

  def create_sales(parsed_orders)
    parsed_orders.each do |order|
      next if Sale.find_by(woo_id: order[:sale][:woo_id])
      customer = Customer.find_or_create_by(order[:customer])
      sale = Sale.create(order[:sale].merge({
        customer_id: customer[:id]
      }))
      order[:products].each do |order_product|
        product = Product.find_by(woo_id: order_product[:product_woo_id])
        next if product.blank?
        variation = if order_product[:variation].present?
          variation_name = Variation.types.values.find { |types| types.include? order_product[:variation][:display_key] }.first
          variation_value = variation_name.constantize.find_or_create_by({
            value: order_product[:variation][:display_value]
          })
          Variation.find_or_create_by({
            :woo_id => order_product[:variation_woo_id],
            variation_name.downcase => variation_value,
            :product => product
          })
        end
        ProductSale.create({
          woo_id: order_product[:order_woo_id],
          qty: order_product[:qty],
          price: order_product[:price],
          sale: sale,
          product:,
          variation:
        })
      end
    end
  end

  def parse_orders(orders)
    orders.map { |order| Sale.deserialize_woo_order(order) }
  end
end
