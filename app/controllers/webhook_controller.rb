class WebhookController < ApplicationController
  skip_before_action :verify_authenticity_token

  def order_to_sale
    verified = verify_webhook(Rails.application.credentials.dig(:hooks, :order))
    return head(:unauthorized) unless verified

    woo_order = JSON.parse(request.body.read, symbolize_names: true)
    job = SyncWooOrdersJob.new
    new_order = job.parse_order(woo_order)

    new_sale = new_order[:sale].merge({
      customer_id: Customer.find_or_create_by(new_order[:customer]).id
    })
    sale = Sale.find_by(woo_id: new_sale[:woo_id]) || Sale.create(new_sale)

    # We use the if-statement below to update only existing sales.
    # Not the ones we just created.
    # But why do we use the "less than" operator?
    # Imagine we have a sale from five days ago.
    # Using unix timestamps:
    #   5 days ago is 1695922520 seconds,
    #   1 minute ago is 1696328559.
    # (1 695 922 520 < 1 696 328 559) == (sale_date < 1.minute.ago)
    if sale.created_at < 1.minute.ago
      sale.update(new_sale)
    end

    new_order[:products].each do |new_product|
      product = Product.find_by(woo_id: new_product[:product_woo_id])
      if product.blank?
        job = SyncWooProductsJob.new
        product = job.get_product(new_product[:product_woo_id])
      end
      product_sale = ProductSale.find_by(woo_id: new_product[:order_woo_id])
      variation = if new_product[:variation].present?
        variation_name = Variation.types.values.find do |types|
          types.include? new_product[:variation][:display_key]
        end.first
        variation_value = variation_name.constantize.find_or_create_by({
          value: sanitize(new_product[:variation][:display_value])
        })
        Variation.find_or_create_by({
          :woo_id => new_product[:variation_woo_id],
          variation_name.downcase => variation_value,
          :product => product
        })
      end
      if product_sale.present?
        product_sale.update(
          qty: new_product[:qty],
          price: new_product[:price]
        )
      else
        ProductSale.create!({
          qty: new_product[:qty],
          price: new_product[:price],
          woo_id: new_product[:order_woo_id],
          product:,
          sale:,
          variation:
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

  def sanitize(string)
    string.tr(" ", " ").gsub(/—|–/, "-").gsub("&amp;", "&").split("|").map { |s| s.strip }.join(" | ")
  end
end
