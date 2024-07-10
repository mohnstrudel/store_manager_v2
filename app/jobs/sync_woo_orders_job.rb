class SyncWooOrdersJob < ApplicationJob
  queue_as :default

  include Gettable
  include Sanitizable

  URL = "https://store.handsomecake.com/wp-json/wc/v3/orders/"
  ORDERS_SIZE = ENV["ORDERS_SIZE"] || 2300
  VARIATION_TYPES = Variation.types.values
  SYNC_VARIATIONS_JOB = SyncWooVariationsJob.new

  def perform(pages = nil)
    woo_orders = api_get_all(URL, ORDERS_SIZE, pages)
    parsed_orders = parse_all(woo_orders)
    create_sales(parsed_orders)
    nil
  end

  def create_sales(parsed_orders)
    parsed_products_woo_ids = parsed_orders
      .pluck(:products)
      .flatten
      .pluck(:product_woo_id)
    products = Product.where(
      woo_id: parsed_products_woo_ids
    )

    parsed_orders.each do |order|
      customer_id = get_customer_id(order[:customer])
      sale = get_sale(order[:sale].merge(customer_id:))

      order[:products].each do |order_product|
        product = if parsed_orders.size > 1
          products.find { |p|
            p.woo_id == order_product[:product_woo_id].to_s
          }
        else
          Product.find_by(woo_id: order_product[:product_woo_id])
        end

        if product.blank?
          product = get_product_from_woo(order_product[:product_woo_id])
        end

        next if product.blank?

        variation = get_variation(order_product[:variation], product)

        product_sale = ProductSale.find_or_initialize_by(
          woo_id: order_product[:order_woo_id]
        )

        product_sale.assign_attributes({
          price: order_product[:price],
          product:,
          qty: order_product[:qty],
          sale:,
          variation:
        }.compact)

        product_sale.save
      end
    end
  end

  def parse_all(orders)
    orders.map { |order| parse(order) }
  end

  def parse(order)
    shipping = [order[:billing], order[:shipping]].reduce do |memo, el|
      el.each { |k, v| memo[k] = v unless v.empty? }
      memo
    end

    {
      sale: {
        address_1: shipping[:address_1],
        address_2: shipping[:address_2],
        city: shipping[:city],
        company: shipping[:company],
        country: shipping[:country],
        discount_total: order[:discount_total],
        note: order[:customer_note],
        postcode: shipping[:postcode],
        shipping_total: order[:shipping_total],
        state: shipping[:state],
        status: order[:status],
        total: order[:total],
        woo_created_at: DateTime.parse(order[:date_created]),
        woo_id: order[:id],
        woo_updated_at: DateTime.parse(order[:date_modified])
      },
      customer: {
        email: shipping[:email].downcase,
        first_name: shipping[:first_name],
        last_name: shipping[:last_name],
        phone: shipping[:phone],
        woo_id: order[:customer_id]
      },
      products: order[:line_items].map { |line_item|
        {
          order_woo_id: line_item[:id],
          price: line_item[:price].to_i + line_item[:total_tax].to_i,
          product_woo_id: line_item[:product_id],
          qty: line_item[:quantity],
          variation: parse_variation(line_item)
        }.compact
      }
    }
  end

  def parse_variation(line_item)
    variation = line_item[:meta_data]
      .find { |el| el[:display_key].in? VARIATION_TYPES.flatten }

    return if variation.nil?

    variation = variation.slice(:display_key, :display_value)
      .transform_keys({
        display_key: :type,
        display_value: :value
      })

    variation[:type] = VARIATION_TYPES.find { |type|
      type.include? variation[:type]
    }.first.downcase

    woo_id = if line_item[:variation_id].to_i.positive?
      line_item[:variation_id]
    end

    variation
      .transform_values { |v| smart_titleize(sanitize(v)) }
      .merge(woo_id:)
  end

  def get_customer_id(parsed_customer)
    customer = if parsed_customer[:woo_id].in? [0, "0", ""]
      Customer.find_or_initialize_by(
        email: parsed_customer[:email]
      )
    else
      Customer.find_or_initialize_by(
        woo_id: parsed_customer[:woo_id]
      )
    end
    customer.assign_attributes(parsed_customer)
    customer.save
    customer.id
  end

  def get_sale(parsed_sale)
    sale = Sale.find_or_initialize_by(woo_id: parsed_sale[:woo_id])
    sale.assign_attributes(parsed_sale)
    sale.save

    sale
  end

  def get_product_from_woo(woo_id)
    job = SyncWooProductsJob.new
    job.get_and_create_product(woo_id)
    Product.find_by(woo_id:)
  end

  def get_variation(parsed_variation, product)
    return if parsed_variation.blank?

    SYNC_VARIATIONS_JOB.create_variation(
      product:,
      variation_woo_id: parsed_variation[:woo_id],
      variation_types: {
        type: parsed_variation[:type],
        value: parsed_variation[:value]
      }
    )
  end
end
