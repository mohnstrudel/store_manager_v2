class WebhookController < ApplicationController
  skip_before_action :verify_authenticity_token

  def order_to_sale
    verified = verify_webhook(Rails.application.credentials.dig(:hooks, :order))
    return head(:unauthorized) unless verified

    parsed_req = JSON.parse(request.body.read, symbolize_names: true)
    order = Sale.deserialize_woo_order(parsed_req)

    order_sale = order[:sale].merge({
      customer_id: Customer.find_or_create_by(order[:customer]).id
    })
    sale = Sale.find_by(woo_id: order_sale[:woo_id]) || Sale.create(order_sale)

    # We use the if-statement below to update only existing sales.
    # Not the ones we just created.
    # But why do we use the "less than" operator?
    # Imagine we have a sale from five days ago.
    # Using unix timestamps:
    #   5 days ago is 1695922520 seconds,
    #   1 minute ago is 1696328559.
    # (1 695 922 520 < 1 696 328 559) == (sale_date < 1.minute.ago)
    if sale.created_at < 1.minute.ago
      sale.update(order_sale)
    end

    order[:products].each do |i|
      product = Product.find_by(woo_id: i[:product_woo_id])
      next if product.blank?
      product_sale = ProductSale.find_by(woo_id: i[:order_woo_id])
      if product_sale.present?
        product_sale.update(qty: i[:qty], price: i[:price])
      else
        ProductSale.create!({
          qty: i[:qty],
          price: i[:price],
          product: product,
          sale: sale,
          woo_id: i[:order_woo_id]
        })
      end
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
end
