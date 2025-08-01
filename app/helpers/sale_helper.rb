module SaleHelper
  def format_sale_status(status)
    status_title = status.titleize

    if Sale.active_status_names.include? status
      "<span class='text-lime-700'>#{status_title}</span>".html_safe
    else
      "<span class='text-red-900'>#{status_title}</span>".html_safe
    end
  end

  def sale_shop_link(sale)
    if sale.shopify_id.present?
      "https://admin.shopify.com/store/68d8f5-af/orders/#{sale.shopify_id_short}"
    else
      "https://store.handsomecake.com/wp-admin/post.php?post=#{sale.woo_id}&action=edit"
    end
  end

  def customer_shop_link(customer)
    if customer.shopify_id.present?
      "https://admin.shopify.com/store/68d8f5-af/customers/#{customer.shopify_id_short}"
    else
      "https://store.handsomecake.com/wp-admin/user-edit.php?user_id=#{customer.woo_id}"
    end
  end
end
