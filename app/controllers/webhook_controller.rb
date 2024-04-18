class WebhookController < ApplicationController
  skip_before_action :verify_authenticity_token

  def update_sale
    verified = verify_webhook(Rails.application.credentials.dig(:hooks, :order))
    return head(:unauthorized) unless verified

    orders_job = SyncWooOrdersJob.new
    parsed_req = JSON.parse(request.body.read, symbolize_names: true)
    parsed_order = orders_job.parse(parsed_req)

    customer_id = handle_customer(parsed_order[:customer])
    sale = handle_sale(parsed_order[:sale].merge({customer_id:}))
    parsed_order[:products].each { |i| handle_parsed_product(i, sale) }

    head(:no_content)
  end

  private

  # "x-wc-webhook-signature" is a HMAC:
  # a base64 encoded HMAC-SHA256 hash of the payload
  def verify_webhook(secret)
    payload = request.body.read
    req_sign = request.headers["x-wc-webhook-signature"]
    calc_sign = Base64.strict_encode64(OpenSSL::HMAC.digest("sha256", secret, payload))
    ActiveSupport::SecurityUtils.secure_compare(calc_sign, req_sign)
  end

  def handle_customer(customer_payload)
    customer = Customer.find_or_initialize_by(woo_id: customer_payload[:woo_id])
    customer.assign_attributes(customer_payload)
    customer.save

    customer.id
  end

  def handle_sale(sale_payload)
    sale = Sale.find_or_initialize_by(woo_id: sale_payload[:woo_id])
    sale.assign_attributes(sale_payload)
    sale.save

    sale
  end

  def get_variation_type(parsed_variation)
    variation_type = Variation.types.values.find do |types|
      types.include? parsed_variation[:display_key]
    end&.first

    return unless variation_type

    variation_value = variation_type.constantize.find_or_create_by({
      value: parsed_variation[:display_value]
    })

    return unless variation_value

    {variation_type.downcase => variation_value}
  end

  def handle_parsed_product(parsed_product, sale)
    product = Product.find_by(woo_id: parsed_product[:product_woo_id])

    if product.blank?
      products_job = SyncWooProductsJob.new
      product = products_job.get_product(parsed_product[:product_woo_id])
    end
    return if product.blank?

    variation = if parsed_product[:variation].present?
      Variation.find_or_create_by({
        woo_id: parsed_product[:variation_woo_id],
        product:
      }.merge(get_variation_type(parsed_product[:variation])))
    end

    product_sale = ProductSale.find_or_initialize_by(
      woo_id: parsed_product[:order_woo_id]
    )

    product_sale.assign_attributes(
      qty: parsed_product[:qty],
      price: parsed_product[:price],
      woo_id: parsed_product[:order_woo_id],
      product:,
      sale:,
      variation:
    )

    product_sale.save
  end
end
