class Shopify::SaleParser
  def initialize(api_item: {})
    @order = api_item
    raise ArgumentError, "api_item must be a Hash" unless @order.is_a?(Hash)
    raise ArgumentError, "api_item cannot be blank" if @order.blank?
  end

  def parse
    {
      sale: parse_sale,
      sale_items: parse_sale_items,
      customer: parse_customer
    }
  end

  private

  def parse_sale
    {
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
      shopify_updated_at: parse_datetime(@order["updatedAt"]),
      status: parse_shopify_status,
      shopify_id: @order["id"],
      total: @order["totalPrice"]
    }
  end

  def parse_customer
    {
      email: find_customer_email,
      first_name: @order.dig("customer", "firstName"),
      last_name: @order.dig("customer", "lastName"),
      phone: find_customer_phone,
      shopify_id: @order.dig("customer", "id")
    }
  end

  def find_customer_email
    email = @order.dig("customer", "email") || @order["email"]
    email&.downcase
  end

  def find_customer_phone
    @order.dig("customer", "phone") || @order["phone"] || @order.dig("shippingAddress", "phone")
  end

  def parse_sale_items
    return [] if @order.dig("lineItems", "nodes").blank?

    @order["lineItems"]["nodes"].map do |line_item|
      parsed_product = if line_item["product"]
        Shopify::ProductParser.new(api_item: line_item["product"]).parse
      end

      {
        price: line_item["originalTotal"],
        qty: line_item["quantity"],
        shopify_id: line_item["id"],
        edition_title: line_item["variantTitle"],
        shopify_edition_id: line_item.dig("variant", "id"),
        shopify_product_id: line_item.dig("variant", "product", "id"),
        full_title: line_item["title"],
        product: parsed_product
      }
    end
  end

  def parse_shopify_status
    fulfillment_status = @order["displayFulfillmentStatus"]
    financial_status = @order["displayFinancialStatus"]

    case [fulfillment_status, financial_status]
    when ["FULFILLED", "PAID"]
      "completed"
    when ["UNFULFILLED", "PAID"]
      "pre-ordered"
    when ["UNFULFILLED", "PENDING"]
      "processing"
    when ["UNFULFILLED", "PARTIALLY_PAID"]
      "partially-paid"
    when ["FULFILLED", "REFUNDED"]
      "refunded"
    when ["UNFULFILLED", "REFUNDED"]
      "cancelled"
    else
      "processing"
    end
  end

  def parse_datetime(datetime_str)
    return nil unless datetime_str
    DateTime.parse(datetime_str)
  rescue ArgumentError
    raise ArgumentError, "Invalid datetime format: #{datetime_str}"
  end
end
