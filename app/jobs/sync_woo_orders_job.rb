class SyncWooOrdersJob < ApplicationJob
  queue_as :default

  include Gettable
  include Sanitizable

  URL = "https://store.handsomecake.com/wp-json/wc/v3/orders/"
  ORDERS_SIZE = ENV["ORDERS_SIZE"] || 2300
  EDITION_TYPES = Edition.types.values
  SYNC_EDITIONS_JOB = SyncWooEditionsJob.new

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

        edition = get_edition(order_product[:edition], product)

        sale_item = SaleItem.find_or_initialize_by(
          woo_id: order_product[:order_woo_id]
        )

        sale_item.assign_attributes({
          price: order_product[:price],
          product:,
          qty: order_product[:qty],
          sale:,
          edition:
        }.compact)

        sale_item.save
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
          edition: parse_edition(line_item)
        }.compact
      }
    }
  end

  def parse_edition(line_item)
    edition = line_item[:meta_data]
      .find { |el| el[:display_key].in? EDITION_TYPES.flatten }

    return if edition.nil?

    edition = edition.slice(:display_key, :display_value)
      .transform_keys({
        display_key: :type,
        display_value: :value
      })

    edition[:type] = EDITION_TYPES.find { |type|
      type.include? edition[:type]
    }.first.downcase

    woo_id = if line_item[:edition_id].to_i.positive?
      line_item[:edition_id]
    end

    edition
      .transform_values { |v| smart_titleize(sanitize(v)) }
      .merge(woo_id:)
  end

  def get_customer_id(parsed_customer)
    customer = if Customer.woo_id_is_valid? parsed_customer[:woo_id]
      Customer.find_or_initialize_by(
        woo_id: parsed_customer[:woo_id]
      )
    else
      Customer.find_or_initialize_by(
        email: parsed_customer[:email]
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

  def get_edition(parsed_edition, product)
    return if parsed_edition.blank?

    SYNC_EDITIONS_JOB.create_edition(
      product:,
      edition_woo_id: parsed_edition[:woo_id],
      edition_types: {
        type: parsed_edition[:type],
        value: parsed_edition[:value]
      }
    )
  end
end
