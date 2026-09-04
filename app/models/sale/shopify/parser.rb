# frozen_string_literal: true

class Sale::Shopify::Parser
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
    parse_addresses
    parse_store_info
    parse_customer
    parse_sale_items
    parse_payment_plan

    {
      sale: @sale,
      addresses: @addresses,
      store_info: @store_info,
      sale_items: @sale_items,
      customer: @customer,
      payment_plan: @payment_plan
    }
  end

  private

  def parse_sale_attributes
    payment = payment_attributes
    @sale = {
      cancel_reason: @order["cancelReason"],
      cancelled_at: parse_datetime(@order["cancelledAt"]),
      closed: @order["closed"],
      closed_at: parse_datetime(@order["closedAt"]),
      confirmed: @order["confirmed"],
      discount_total: converted_money(@order["totalDiscountsSet"]),
      financial_status: @order["displayFinancialStatus"],
      fulfillment_status: @order["displayFulfillmentStatus"],
      shopify_name: @order["name"],
      note: @order["note"],
      return_status: @order["returnStatus"],
      shipping_total: converted_money(@order["totalShippingPriceSet"]),
      shopify_created_at: shopify_created_at,
      status: derive_status,
      total: converted_money(@order["totalPriceSet"]),
      settlement_status: Sale.settlement_status_from_shopify(
        financial_status: @order["displayFinancialStatus"],
        outstanding_revenue: payment[:outstanding_revenue]
      ),
      **payment,
      **currency_attributes
    }
  end

  def payment_attributes
    {
      expected_revenue: converted_money(@order["currentTotalPriceSet"]) || converted_money(@order["totalPriceSet"]),
      received_revenue: converted_money(@order["totalReceivedSet"]),
      outstanding_revenue: converted_money(@order["totalOutstandingSet"]),
      refunded_revenue: converted_money(@order["totalRefundedSet"]),
      net_payment: converted_money(@order["netPaymentSet"]),
      payment_gateway_names: Array(@order["paymentGatewayNames"]),
      payment_terms_name: @order.dig("paymentTerms", "paymentTermsName"),
      payment_terms_type: @order.dig("paymentTerms", "paymentTermsType"),
      payment_due: next_payment_due,
      payment_overdue: @order.dig("paymentTerms", "overdue") || false
    }
  end

  def converted_money(money_set)
    amount = money_set&.dig("shopMoney", "amount")
    return nil if amount.blank?

    order_conversion&.usd_amount(amount)
  end

  def order_conversion
    return @order_conversion if defined?(@order_conversion)

    @order_conversion = shopify_created_at && ExchangeRate.eur_to_usd_conversion(date: shopify_created_at.to_date)
  end

  def shopify_created_at
    @shopify_created_at ||= parse_datetime(@order["createdAt"])
  end

  def parse_datetime(datetime_str)
    return nil unless datetime_str

    DateTime.parse(datetime_str)
  rescue ArgumentError
    raise ArgumentError, "Invalid datetime format: #{datetime_str}"
  end

  def next_payment_due
    schedules = payment_schedules
    return nil if schedules.blank?

    schedules
      .select { |schedule| schedule["completedAt"].nil? && schedule["dueAt"].present? }
      .filter_map { |schedule| parse_datetime(schedule["dueAt"]) }
      .min
  end

  def payment_schedules
    Array(@order.dig("paymentTerms", "paymentSchedules", "nodes"))
  end

  def derive_status
    Sale.derive_status_from_shopify(@order["displayFulfillmentStatus"], @order["displayFinancialStatus"])
  end

  def currency_attributes
    return {shop_currency: nil, presentment_currency: nil, usd_conversion_rate: nil, exchange_rate_date: nil} unless order_conversion

    {
      shop_currency: @order["currencyCode"],
      presentment_currency: @order["presentmentCurrencyCode"],
      usd_conversion_rate: order_conversion.rate,
      exchange_rate_date: order_conversion.effective_date
    }
  end

  def parse_addresses
    @addresses = {
      shipping: address_attributes("shippingAddress"),
      billing: address_attributes("billingAddress", email: find_customer_email)
    }
  end

  def address_attributes(key, email: nil)
    {
      first_name: @order.dig(key, "firstName"),
      last_name: @order.dig(key, "lastName"),
      email:,
      phone: @order.dig(key, "phone"),
      company: @order.dig(key, "company"),
      address_1: @order.dig(key, "address1"),
      address_2: @order.dig(key, "address2"),
      city: @order.dig(key, "city"),
      state: @order.dig(key, "provinceCode") || @order.dig(key, "province"),
      postcode: @order.dig(key, "zip"),
      country: @order.dig(key, "country")
    }.compact_blank
  end

  def find_customer_email
    (
      @order.dig("customer", "defaultEmailAddress", "emailAddress") ||
      @order["email"]
    )&.downcase
  end

  def parse_store_info
    @store_info = {
      store_id: @order["id"],
      ext_created_at: shopify_created_at,
      ext_updated_at: parse_datetime(@order["updatedAt"])
    }
  end

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

  def find_customer_phone
    @order.dig("customer", "defaultPhoneNumber", "phoneNumber") ||
      @order["phone"] ||
      @order.dig("billingAddress", "phone") ||
      @order.dig("shippingAddress", "phone")
  end

  def parse_sale_items
    @sale_items = if @order.dig("lineItems", "nodes").blank?
      []
    else
      @order["lineItems"]["nodes"].map do |line_item|
        product_store_id = line_item.dig("variant", "product", "id") || line_item.dig("product", "id")
        parsed_product = parse_product(line_item["product"], product_store_id)

        {
          price: converted_money(line_item["originalTotalSet"]),
          expected_revenue: converted_money(line_item["discountedTotalSet"]) || converted_money(line_item["originalTotalSet"]),
          qty: line_item["quantity"],
          store_id: line_item["id"],
          variant_title: line_item["variantTitle"],
          variant_store_id: line_item.dig("variant", "id"),
          product_store_id: product_store_id,
          full_title: line_item["title"],
          product: parsed_product
        }
      end
    end
  end

  def parse_product(product_payload, product_store_id)
    return nil if product_payload.blank?
    return nil if product_payload["title"].blank?

    Product::Shopify::Parser.parse(product_payload).merge(store_id: product_store_id || product_payload["id"])
  end

  def parse_payment_plan
    terms = @order["paymentTerms"]
    schedules = payment_schedules
    @payment_plan = nil
    return if terms.blank? || terms["id"].blank? || schedules.blank?

    next_due_at = next_payment_due
    raw_total = projected_total(schedules)
    @payment_plan = {
      attributes: {
        provider: "shopify",
        external_id: terms["id"],
        external_origin_order_id: @order["id"],
        kind: "payment_terms",
        status: payment_plan_status(terms, schedules),
        expected_parts: schedules.size,
        projected_total: order_conversion&.usd_amount(raw_total),
        deposit_percent: deposit_percent(schedules, raw_total),
        next_due_at:
      },
      parts: schedules.each_with_index.map { |schedule, index|
        {
          provider_part_id: schedule["id"],
          sequence: index + 1,
          external_order_id: @order["id"],
          amount: order_conversion&.usd_amount(schedule_total_balance(schedule)),
          due_at: parse_datetime(schedule["dueAt"]),
          provider_completed_at: parse_datetime(schedule["completedAt"])
        }
      }
    }
  end

  def projected_total(schedules)
    schedules.sum { |schedule| schedule_total_balance(schedule) }
  end

  def schedule_total_balance(schedule)
    schedule.dig("totalBalance", "amount").to_d
  end

  def payment_plan_status(terms, schedules)
    return "completed" if schedules.all? { |schedule| schedule["completedAt"].present? }
    return "overdue" if terms["overdue"]

    "active"
  end

  def deposit_percent(schedules, total)
    return if schedules.size <= 1 || total.zero?

    amounts = schedules.map { |schedule| schedule_total_balance(schedule) }
    return if amounts.uniq.size <= 1

    (amounts.first / total * 100).round(2)
  end
end
