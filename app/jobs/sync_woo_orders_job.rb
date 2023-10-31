class SyncWooOrdersJob < ApplicationJob
  queue_as :default

  URL = "https://store.handsomecake.com/wp-json/wc/v3/orders/"
  CONSUMER_KEY = Rails.application.credentials.dig(:woo_api, :user)
  CONSUMER_SECRET = Rails.application.credentials.dig(:woo_api, :pass)
  SIZE = 1800
  PER_PAGE = 100

  def perform(*args)
    convert_orders_to_sales
  end

  def convert_orders_to_sales
    Product.sync_woo_products unless Product.any?
    sync_errors = []
    get_orders.each do |order|
      next if Sale.find_by(woo_id: order[:sale][:woo_id])
      customer = Customer.find_or_create_by(order[:customer])
      sale = Sale.create(order[:sale].merge({
        customer_id: customer[:id]
      }))
      unless sale.persisted?
        sync_errors.push(order[:sale].merge({
          customer_id: customer[:id]
        }))
      end
      order[:products].each do |i|
        product = Product.find_by(woo_id: i[:product_woo_id])
        next if product.blank?
        ps = ProductSale.create!({
          qty: i[:qty],
          price: i[:price],
          product: product,
          sale: sale,
          woo_id: i[:order_woo_id]
        })
        unless ps.persisted?
          sync_errors.push({
            qty: i[:qty],
            price: i[:price],
            product: product,
            sale: sale,
            woo_id: i[:order_woo_id]
          })
        end
      end
    rescue => e
      Rails.logger.error "Full error: #{e}"
      Rails.logger.error "Error occurred at #{e.backtrace.first}"
    end
    if sync_errors.any?
      file_path = Rails.root.join("sync_orders_err.json")
      File.write(file_path, JSON.generate(sync_errors))
    end
  end

  def get_orders(size = SIZE, per_page = PER_PAGE)
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
      parsed_response = JSON.parse(response.body, symbolize_names: true)
      deserialized_orders = parsed_response.map do |i|
        Sale.deserialize_woo_order(i)
      end
      orders.concat(deserialized_orders)
      page += 1
    end
    orders
  end
end
