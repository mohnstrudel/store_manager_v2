class WebhookController < ApplicationController
  skip_before_action :verify_authenticity_token

  SYNC_ORDERS_JOB = SyncWooOrdersJob.new
  SYNC_VARIATIONS_JOB = SyncWooVariationsJob.new

  def process_order
    verified = verify_webhook(Rails.application.credentials.dig(:hooks, :order))
    return head(:unauthorized) unless verified

    parsed_req = JSON.parse(request.body.read, symbolize_names: true)
    parsed_order = SYNC_ORDERS_JOB.parse(parsed_req)

    if Sale.find_by(woo_id: parsed_order[:sale][:woo_id]).blank?
      SYNC_ORDERS_JOB.create_sales([parsed_order])
    else
      customer_id = update_customer(parsed_order[:customer])
      sale = update_sale(parsed_order[:sale].merge({customer_id:}))
      parsed_order[:products].each { |i| update_parsed_product(i, sale) }
    end

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

  def update_customer(customer_payload)
    customer = Customer.find_or_initialize_by(woo_id: customer_payload[:woo_id])
    customer.assign_attributes(customer_payload)
    customer.save

    customer.id
  end

  def update_sale(sale_payload)
    sale = Sale.find_or_initialize_by(woo_id: sale_payload[:woo_id])
    sale.assign_attributes(sale_payload)
    sale.save

    sale
  end

  def update_parsed_product(parsed_product, sale)
    product = Product.find_by(woo_id: parsed_product[:product_woo_id])

    if product.blank?
      products_job = SyncWooProductsJob.new
      product = products_job.get_product(parsed_product[:product_woo_id])
    end
    return if product.blank?

    variation = if parsed_product[:variation].present?
      Variation.find_by(woo_id: parsed_product[:variation_woo_id]).presence ||
        SYNC_VARIATIONS_JOB.create_variation(
          product: parsed_product,
          variation_woo_id: parsed_product[:variation_woo_id],
          variation_types: parsed_product[:variation]
        )
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
