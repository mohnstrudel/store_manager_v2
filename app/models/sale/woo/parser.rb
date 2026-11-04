# frozen_string_literal: true

class Sale::Woo::Parser
  PARTIALLY_PAID_STATUS = "partially-paid"
  DEPOSIT_AMOUNT_META_KEY = "_awcdp_deposits_deposit_amount"
  DEPOSIT_PAID_META_KEY = "_awcdp_deposits_deposit_paid"

  class << self
    def parse_all(orders)
      orders.map { |order| parse(order) }.compact
    end

    def parse(order)
      return if order.blank?

      shipping = parse_address(order[:shipping])
      billing = parse_address(order[:billing])
      customer_address = billing.presence || shipping
      sale_date = order_date(order)
      currency = order[:currency]

      {
        sale: {
          discount_total: convert(order[:discount_total], currency:, date: sale_date),
          note: order[:customer_note],
          shipping_total: convert(order[:shipping_total], currency:, date: sale_date),
          status: order[:status],
          total: convert(order[:total], currency:, date: sale_date),
          settlement_status: Sale.settlement_status_from_woo(status: order[:status], date_paid: order[:date_paid]),
          woo_created_at: parse_woo_datetime(order[:date_created]),
          woo_id: order[:id],
          woo_updated_at: parse_woo_datetime(order[:date_modified]),
          **payment_attributes(order, currency:, date: sale_date)
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
        products: order[:line_items].map { |line_item|
          {
            sale_item_woo_id: line_item[:id],
            price: convert(line_item[:price].to_i + line_item[:total_tax].to_i, currency:, date: sale_date),
            expected_revenue: convert(line_item[:total].to_d + line_item[:total_tax].to_d, currency:, date: sale_date),
            product_woo_id: line_item[:product_id],
            qty: line_item[:quantity],
            variant: Variant::Woo::Parser.parse_order_line_item(line_item)
          }.compact
        }
      }.compact
    end

    private

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

    def order_date(order)
      DateTime.parse(order[:date_created]).to_date if order[:date_created].present?
    end

    def convert(amount, currency:, date:)
      return nil if amount.blank?

      ExchangeRate.usd_amount(amount, currency:, date:)
    end

    def parse_woo_datetime(value)
      return if value.blank?

      DateTime.parse(value).iso8601
    end

    def payment_attributes(order, currency:, date:)
      refunded = order[:refunds].to_a.sum(0.to_d) { |refund| refund[:total].to_d.abs }

      {
        expected_revenue: convert(order[:total], currency:, date:),
        **payment_split(order, currency:, date:),
        refunded_revenue: convert(refunded, currency:, date:),
        payment_gateway_names: [order[:payment_method_title]].compact_blank
      }
    end

    def payment_split(order, currency:, date:)
      return partially_paid_split(order, currency:, date:) if order[:status] == PARTIALLY_PAID_STATUS

      paid = order[:date_paid].present?
      total = order[:total]

      {
        received_revenue: convert(paid ? total : 0, currency:, date:),
        outstanding_revenue: convert(paid ? 0 : total, currency:, date:)
      }
    end

    def partially_paid_split(order, currency:, date:)
      deposit_paid = woo_meta_value(order, DEPOSIT_PAID_META_KEY)
      deposit_amount = woo_meta_value(order, DEPOSIT_AMOUNT_META_KEY)

      {
        received_revenue: (deposit_paid == "yes") ? convert(deposit_amount, currency:, date:) : nil,
        outstanding_revenue: nil
      }
    end

    def woo_meta_value(order, key)
      order[:meta_data].to_a.find { |meta| meta[:key] == key }&.dig(:value)
    end
  end
end
