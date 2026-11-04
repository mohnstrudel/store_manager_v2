# frozen_string_literal: true

class Sale::Woo::Parser
  PARTIALLY_PAID_STATUS = "partially-paid"
  DEPOSIT_AMOUNT_META_KEY = "_awcdp_deposits_deposit_amount"
  DEPOSIT_PAID_META_KEY = "_awcdp_deposits_deposit_paid"

  attr_reader :order
  private :order

  def self.parse_all(orders)
    orders.map { |order| parse(order) }.compact
  end

  def self.parse(order)
    return if order.blank?

    new(order).parse
  end

  def initialize(order)
    @order = order
  end

  def parse
    {
      sale: {
        discount_total: convert(order[:discount_total]),
        note: order[:customer_note],
        shipping_total: convert(order[:shipping_total]),
        status: order[:status],
        total: convert(order[:total]),
        settlement_status:,
        woo_created_at: parse_woo_datetime(order[:date_created]),
        woo_id: order[:id],
        woo_updated_at: parse_woo_datetime(order[:date_modified]),
        **payment_attributes
      },
      addresses: {
        shipping:,
        billing:
      },
      customer: {
        email: customer_address[:email]&.downcase,
        first_name: customer_address[:first_name],
        last_name: customer_address[:last_name],
        phone: customer_address[:phone],
        woo_id: order[:customer_id]
      },
      products: order[:line_items].map { |line_item| parse_line_item(line_item) }
    }.compact
  end

  private

  def convert(amount)
    return nil if amount.blank?

    ExchangeRate.usd_amount(amount, currency: order[:currency], date: sale_date)
  end

  def sale_date
    return @sale_date if defined?(@sale_date)

    @sale_date = (DateTime.parse(order[:date_created]).to_date if order[:date_created].present?)
  end

  def settlement_status
    return "not_fully_paid" if order[:status] == PARTIALLY_PAID_STATUS

    case order[:status]
    when *Sale::STATUSES
      order[:date_paid].present? ? "paid" : "not_fully_paid"
    else
      raise ArgumentError, "Unmapped Woo status: #{order[:status].inspect}"
    end
  end

  def parse_woo_datetime(value)
    return if value.blank?

    DateTime.parse(value).iso8601
  end

  def payment_attributes
    refunded = order[:refunds].to_a.sum(0.to_d) { |refund| refund[:total].to_d.abs }

    {
      expected_revenue: convert(order[:total]),
      **payment_split,
      refunded_revenue: convert(refunded),
      payment_gateway_names: [order[:payment_method_title]].compact_blank
    }
  end

  def payment_split
    return partially_paid_split if order[:status] == PARTIALLY_PAID_STATUS

    paid = order[:date_paid].present?
    total = order[:total]

    {
      received_revenue: convert(paid ? total : 0),
      outstanding_revenue: convert(paid ? 0 : total)
    }
  end

  def partially_paid_split
    deposit_paid = woo_meta_value(DEPOSIT_PAID_META_KEY)
    deposit_amount = woo_meta_value(DEPOSIT_AMOUNT_META_KEY)

    {
      received_revenue: (deposit_paid == "yes") ? convert(deposit_amount) : nil,
      outstanding_revenue: nil
    }
  end

  def woo_meta_value(key)
    order[:meta_data].to_a.find { |meta| meta[:key] == key }&.dig(:value)
  end

  def shipping
    @shipping ||= parse_address(order[:shipping])
  end

  def parse_address(address)
    return {} if address.blank?

    {
      first_name: address[:first_name],
      last_name: address[:last_name],
      email: address[:email],
      phone: address[:phone],
      company: address[:company],
      address_1: address[:address_1],
      address_2: address[:address_2],
      city: address[:city],
      state: address[:state],
      postcode: address[:postcode],
      country: address[:country]
    }.transform_values { |value| value.presence || "" }
  end

  def billing
    @billing ||= parse_address(order[:billing])
  end

  def customer_address
    @customer_address ||= billing.presence || shipping
  end

  def parse_line_item(line_item)
    {
      sale_item_woo_id: line_item[:id],
      price: convert(line_item[:price].to_i + line_item[:total_tax].to_i),
      expected_revenue: convert(line_item[:total].to_d + line_item[:total_tax].to_d),
      product_woo_id: line_item[:product_id],
      qty: line_item[:quantity],
      variant: Variant::Woo::Parser.parse_order_line_item(line_item)
    }.compact
  end
end
