# frozen_string_literal: true

class Sale
  class ShopifyParser
    include Sanitizable

    def self.parse(payload)
      raise ArgumentError, "Payload cannot be blank" if payload.blank?
      return payload if payload.key?(:store_id)

      new(payload).parse
    end

    def initialize(payload)
      @order = payload
    end

    def parse
      parse_sale_attributes
      parse_store_info
      parse_customer
      parse_sale_items

      {
        sale: @sale,
        store_info: @store_info,
        sale_items: @sale_items,
        customer: @customer
      }
    end

    private

    def parse_sale_attributes
      @sale = {
        address_1: @order.dig("shippingAddress", "address1"),
        address_2: @order.dig("shippingAddress", "address2"),
        cancel_reason: @order["cancelReason"],
        cancelled_at: parse_datetime(@order["cancelledAt"]),
        city: @order.dig("shippingAddress", "city"),
        closed: @order["closed"],
        closed_at: parse_datetime(@order["closedAt"]),
        company: @order.dig("shippingAddress", "company"),
        confirmed: @order["confirmed"],
        country: @order.dig("shippingAddress", "country"),
        discount_total: @order["totalDiscounts"],
        financial_status: @order["displayFinancialStatus"],
        fulfillment_status: @order["displayFulfillmentStatus"],
        shopify_name: @order["name"],
        note: @order["note"],
        postcode: @order.dig("shippingAddress", "zip"),
        return_status: @order["returnStatus"],
        shipping_total: @order["totalShippingPrice"],
        shopify_created_at: parse_datetime(@order["createdAt"]),
        status: derive_status,
        store_id: @order["id"],
        total: @order["totalPrice"]
      }
    end

    def parse_store_info
      @store_info = {
        ext_created_at: parse_datetime(@order["createdAt"]),
        ext_updated_at: parse_datetime(@order["updatedAt"])
      }
    end

    # Customers may be guests without Shopify ID
    def parse_customer
      @customer = {
        email: find_customer_email,
        phone: find_customer_phone,
        first_name: @order.dig("customer", "firstName"),
        last_name: @order.dig("customer", "lastName"),
        store_info: {
          store_id: @order.dig("customer", "id"),
          ext_created_at: parse_datetime(@order.dig("customer", "createdAt")),
          ext_updated_at: parse_datetime(@order.dig("customer", "updatedAt"))
        }.compact
      }.compact_blank
    end

    def find_customer_email
      email = @order.dig("customer", "email") || @order["email"]
      email&.downcase
    end

    def find_customer_phone
      @order.dig("customer", "phone") || @order["phone"] || @order.dig("shippingAddress", "phone")
    end

    def parse_sale_items
      @sale_items = if @order.dig("lineItems", "nodes").blank?
        []
      else
        @order["lineItems"]["nodes"].map do |line_item|
          parsed_product = line_item["product"] ? Product::ShopifyParser.parse(line_item["product"]) : nil

          {
            price: line_item["originalTotal"],
            qty: line_item["quantity"],
            store_id: line_item["id"],
            edition_title: line_item["variantTitle"],
            edition_store_id: line_item.dig("variant", "id"),
            product_store_id: line_item.dig("variant", "product", "id"),
            full_title: line_item["title"],
            product: parsed_product
          }
        end
      end
    end

    def derive_status
      Sale.derive_status_from_shopify(
        @order["displayFulfillmentStatus"],
        @order["displayFinancialStatus"]
      )
    end

    def parse_datetime(datetime_str)
      return nil unless datetime_str
      DateTime.parse(datetime_str)
    rescue ArgumentError
      raise ArgumentError, "Invalid datetime format: #{datetime_str}"
    end
  end
end
