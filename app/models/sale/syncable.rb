# frozen_string_literal: true

module Sale::Syncable
  extend ActiveSupport::Concern

  class_methods do
    def find_recent_by_order_id(shop_order_id)
      if shop_order_id.upcase.include?("HSCM#")
        Sale.find_by(shopify_name: shop_order_id)
      else
        Sale
          .left_outer_joins(:woo_info)
          .where(
            "sales.shopify_name LIKE :shop_order_id OR store_infos.store_id = :exact_order_id",
            shop_order_id: "%#{shop_order_id}",
            exact_order_id: shop_order_id
          )
          .max_by(&:shop_created_at)
      end
    end
  end

  def shop_created_at
    shopify_created_at || woo_created_at
  end

  def shop_updated_at
    shopify_info&.ext_updated_at || woo_updated_at
  end

  def shop_currency_amount(usd_amount)
    return if usd_amount.nil? || shop_currency.blank? || shop_currency == "USD" || !usd_conversion_rate&.positive?

    (usd_amount.to_d / usd_conversion_rate).round(2)
  end

  def push_status_to_woo_later
    Woo::PushSaleJob.perform_later(self)
  end

  def push_status_to_woo_now
    Woo::Api::Client.new.update_order_status(woo_store_id, status)
  end
end
