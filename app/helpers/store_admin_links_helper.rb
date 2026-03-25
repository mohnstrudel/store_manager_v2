# frozen_string_literal: true

module StoreAdminLinksHelper
  def sale_shop_link(sale)
    if sale.shopify_info&.store_id&.present?
      "https://admin.shopify.com/store/68d8f5-af/orders/#{sale.shopify_info.id_short}"
    else
      "https://store.handsomecake.com/wp-admin/post.php?post=#{sale.woo_info&.store_id}&action=edit"
    end
  end

  def customer_shop_link(customer)
    if customer.shopify_info&.store_id&.present?
      "https://admin.shopify.com/store/68d8f5-af/customers/#{customer.shopify_info.id_short}"
    else
      "https://store.handsomecake.com/wp-admin/user-edit.php?user_id=#{customer.woo_info&.store_id}"
    end
  end
end
