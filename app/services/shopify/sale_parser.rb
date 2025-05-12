class Shopify::SaleParser
  def initialize(api_order)
    @order = api_order || {}
    raise ArgumentError, "Order data is required" if @order.blank?
  end

  def parse
    return if @order.blank?

    {
      sale: parse_sale,
      product_sales: parse_product_sales,
      customer: parse_customer
    }
  end

  private

  def parse_sale
    {
      address_1: @order["shippingAddress"].try(:[], "address1"),
      address_2: @order["shippingAddress"].try(:[], "address2"),
      cancel_reason: @order["cancelReason"],
      cancelled_at: @order["cancelledAt"] ? DateTime.parse(@order["cancelledAt"]) : nil,
      city: @order["shippingAddress"].try(:[], "city"),
      closed: @order["closed"],
      closed_at: @order["closedAt"] ? DateTime.parse(@order["closedAt"]) : nil,
      company: @order["shippingAddress"].try(:[], "company"),
      confirmed: @order["confirmed"],
      country: @order["shippingAddress"].try(:[], "country"),
      discount_total: @order["totalDiscounts"],
      financial_status: @order["displayFinancialStatus"],
      fulfillment_status: @order["displayFulfillmentStatus"],
      note: @order["note"],
      postcode: @order["shippingAddress"].try(:[], "zip"),
      return_status: @order["returnStatus"],
      shipping_total: @order["totalShippingPrice"],
      shopify_created_at: DateTime.parse(@order["createdAt"]),
      shopify_updated_at: DateTime.parse(@order["updatedAt"]),
      status: parse_shopify_status,
      shopify_id: @order["id"],
      total: @order["totalPrice"]
    }
  end

  def parse_customer
    {
      email: @order["customer"]["email"]&.downcase || @order["email"]&.downcase,
      first_name: @order["customer"]["firstName"],
      last_name: @order["customer"]["lastName"],
      phone: find_customer_phone,
      shopify_id: @order["customer"]["id"]
    }
  end

  def find_customer_phone
    @order["customer"]["phone"] || @order["phone"] || @order.dig("shippingAddress", "phone")
  end

  def parse_product_sales
    @order["lineItems"]["nodes"].map do |line_item|
      parsed_product = if line_item["product"]
        Shopify::ProductParser.new(api_product: line_item["product"]).parse
      end
      {
        price: line_item["originalTotal"],
        qty: line_item["quantity"],
        shopify_id: line_item["id"],
        variation_title: line_item["variantTitle"],
        shopify_variation_id: line_item.dig("variant", "id"),
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
end
