# frozen_string_literal: true

module Product::Shopify::Publishing
  def publish_on_shopify!(store_id:, slug:, pushed_at: Time.current)
    raise ArgumentError, "Store ID cannot be blank" if store_id.blank?

    store_info = shopify_info || store_infos.shopify.new

    store_info.assign_attributes(
      push_time: pushed_at,
      store_id:,
      slug:
    )
    store_info.save!
    store_info
  end
end
