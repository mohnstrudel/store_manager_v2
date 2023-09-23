class SyncWooOrdersJob < ApplicationJob
  queue_as :default

  URL = "https://store.handsomecake.com/wp-json/wc/v3/orders/"
  CONSUMER_KEY = Rails.application.credentials.dig(:woo_api, :user)
  CONSUMER_SECRET = Rails.application.credentials.dig(:woo_api, :pass)
  SIZE = 1542
  PER_PAGE = 100

  def perform(*args)
    save_woo_orders_to_db
  end

  def save_woo_orders_to_db
    get_woo_orders(method(:map_woo_orders_to_sales)).each do |woo_order|
      next if Sale.find_by(woo_id: woo_order[:sale][:woo_id])
      customer = Customer.find_or_create_by(woo_order[:customer])
      sale = Sale.create(woo_order[:sale].merge({
        customer_id: customer[:id]
      }))
      woo_order[:products].each do |i|
        product = Product.find_by(woo_id: i[:woo_id])
        next if product.blank?
        ProductSale.create!({
          qty: i[:qty],
          price: i[:price],
          product: product,
          sale: sale
        })
      end
    rescue => e
      Rails.logger.error "Full error: #{e}"
      Rails.logger.error "Error occurred at #{e.backtrace.first}"
    end
  end

  def get_woo_orders(mapper, size = SIZE, per_page = PER_PAGE)
    pages = (size / per_page).ceil
    page = 1
    orders = []
    while page <= pages
      response = HTTParty.get(
        URL,
        query: {
          per_page: per_page,
          page: page
        },
        basic_auth: {
          username: CONSUMER_KEY,
          password: CONSUMER_SECRET
        }
      )
      woo_orders = JSON.parse(response.body, symbolize_names: true)
      result = mapper.call(woo_orders)
      orders.concat(result)
      page += 1
    end
    orders
  end

  def map_woo_orders_to_sales(orders)
    orders.map do |order|
      shipping = [order[:billing], order[:shipping]].reduce do |memo, el|
        el.each { |k, v| memo[k] = v unless v.empty? }
        memo
      end
      {
        sale: {
          woo_id: order[:id],
          status: order[:status],
          woo_created_at: DateTime.parse(order[:date_created]),
          woo_updated_at: DateTime.parse(order[:date_modified]),
          total: order[:total],
          shipping_total: order[:shipping_total],
          discount_total: order[:discount_total],
          note: order[:customer_note],
          address_1: shipping[:address_1],
          address_2: shipping[:address_2],
          city: shipping[:city],
          company: shipping[:company],
          country: shipping[:country],
          postcode: shipping[:postcode],
          state: shipping[:state]
        },
        customer: {
          woo_id: order[:customer_id],
          first_name: shipping[:first_name],
          last_name: shipping[:last_name],
          phone: shipping[:phone],
          email: shipping[:email]
        },
        products: order[:line_items].map { |i|
          {
            woo_id: i[:product_id],
            qty: i[:quantity],
            price: i[:price]
          }
        }
      }
    end
  end
end
