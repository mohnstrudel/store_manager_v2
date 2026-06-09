# frozen_string_literal: true

module ShippingCompanyHelper
  def shipping_company_form_props(shipping_company)
    {
      shippingCompany: shipping_company_props(shipping_company)
    }
  end

  def shipping_company_props(shipping_company)
    {
      created_at: formatted_timestamp(shipping_company.created_at),
      id: shipping_company.id,
      name: shipping_company.name.to_s,
      tracking_url: shipping_company.tracking_url.presence,
      updated_at: formatted_timestamp(shipping_company.updated_at)
    }
  end

  def shipping_company_purchase_item_props(purchase_item)
    {
      id: purchase_item.id,
      path: purchase_item_path(purchase_item),
      product_full_title: purchase_item.product.full_title,
      purchased_ago: time_ago_in_words(purchase_item.purchase&.date || purchase_item.created_at),
      tracking_number: purchase_item.tracking_number
    }
  end
end
