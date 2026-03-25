# frozen_string_literal: true

module Sale::ShopSync
  extend ActiveSupport::Concern

  class_methods do
    def update_order(sale)
      Woo::PushSaleJob.perform_later(sale)
    end

    def find_recent_by_order_id(shop_order_id)
      if shop_order_id.upcase.include?("HSCM#")
        Sale.find_by(shopify_name: shop_order_id)
      else
        Sale.where(
          "shopify_name LIKE ? OR woo_id = ?", "%#{shop_order_id}", shop_order_id
        ).max_by(&:shop_created_at)
      end
    end
  end

  def shop_created_at
    shopify_created_at || woo_created_at
  end

  def shop_updated_at
    shopify_info&.ext_updated_at || woo_updated_at
  end

  def sync_status_change_to_shop!
    self.class.update_order(self)
  end
end
