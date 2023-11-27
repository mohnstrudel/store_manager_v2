class SyncWooOrdersJob < ApplicationJob
  queue_as :default

  URL = "https://store.handsomecake.com/wp-json/wc/v3/orders/"
  CONSUMER_KEY = Rails.application.credentials.dig(:woo_api, :user)
  CONSUMER_SECRET = Rails.application.credentials.dig(:woo_api, :pass)
  SIZE = 1800
  PER_PAGE = 100

  def perform(*args)
    woo_orders = get_woo_orders
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

  def get_woo_orders
    progressbar = ProgressBar.create(title: "SyncWooOrdersJob")
    step = 100 / (SIZE / PER_PAGE)
    pages = (SIZE / PER_PAGE).ceil
    page = 1
    orders = []
    while page <= pages
      response = HTTParty.get(
        URL,
        query: {
          per_page: PER_PAGE,
          page:
        },
        basic_auth: {
          username: CONSUMER_KEY,
          password: CONSUMER_SECRET
        }
      )
      orders.concat(JSON.parse(response.body, symbolize_names: true))
      step.times {
        progressbar.increment
        sleep 0.5
      }
      page += 1
    end
    orders
  end

  def parse_orders(orders)
    orders.map { |order| Sale.deserialize_woo_order(order) }
  end
end
