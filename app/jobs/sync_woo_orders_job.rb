class SyncWooOrdersJob < ApplicationJob
  queue_as :default

  include Gettable

  URL = "https://store.handsomecake.com/wp-json/wc/v3/orders/"
  ORDERS_SIZE = 1800

  def perform
    woo_orders = api_get_all(URL, ORDERS_SIZE)
    parsed_orders = parse_all(woo_orders)
    create_sales(parsed_orders)
    nil
  end

  def create_sales(parsed_orders)
    parsed_orders.each do |order|
      sale = Sale.find_or_create_by(order[:sale].merge({
        customer_id: Customer.find_or_create_by(order[:customer]).id
      }))
      order[:products].each do |order_product|
        product = Product.find_by(woo_id: order_product[:product_woo_id])
        if product.blank?
          job = SyncWooProductsJob.new
          job.get_product(order_product[:product_woo_id])
          product = Product.find_by(woo_id: order_product[:product_woo_id])
        end
        next if product.blank?
        variation = if order_product[:variation].present?
          variation_type = Variation.types.values.find do |type|
            type.include? order_product[:variation][:display_key]
          end.first
          size = Size.parse_size(order_product[:variation][:display_value])
          variation_value = variation_type.constantize.find_or_create_by({
            value: size.presence || order_product[:variation][:display_value]
          })
          Variation.find_or_create_by({
            :woo_id => order_product[:variation_woo_id],
            variation_type.downcase => variation_value,
            :product => product
          }.compact)
        end
        ProductSale.find_or_create_by({
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

  def parse_all(orders)
    orders.map { |order| parse(order) }
  end

  def parse(order)
    variation_types = Variation.types.values.flatten
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
      products: order[:line_items].map { |line_item|
        variation_woo_id = if line_item[:variation_id].to_i.positive?
          line_item[:variation_id]
        end
        variation = line_item[:meta_data]
          .find { |meta| variation_types.include? meta[:display_key] }
          &.slice(:display_key, :display_value)
          &.transform_values { |v| sanitize(v) }
        parsed_variation = variation.present? ?
          {variation_woo_id:, variation:}.compact :
          {}
        {
          product_woo_id: line_item[:product_id],
          qty: line_item[:quantity],
          price: line_item[:price].to_i + line_item[:total_tax].to_i,
          order_woo_id: line_item[:id]
        }.merge(parsed_variation)
      }
    }
  end

  private

  def sanitize(string)
    string.tr(" ", " ").gsub(/—|–/, "-").gsub("&amp;", "&").split("|").map { |s| s.strip }.join(" | ")
  end
end
