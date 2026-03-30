# frozen_string_literal: true

module SaleHelper
  def sale_summary_for_warehouse(sale)
    [sale.customer.full_name, sale.address_1, sale.address_2, sale.postcode, sale.city, sale.country, sale.customer.phone].compact_blank.join(", ")
  end

  def sale_address_for_clipboard(sale)
    [
      sale.customer.full_name,
      sale.address_2,
      sale.address_1,
      [sale.postcode, sale.city].compact_blank.join(" ").presence,
      sale.country,
      sale.customer.phone
    ].compact_blank.join("\n")
  end

  def format_sale_status(status)
    status_title = status.titleize

    if Sale.active_status_names.include? status
      content_tag(:span, status_title, class: "text-lime-700")
    else
      content_tag(:span, status_title, class: "text-red-900")
    end
  end

  def shop_admin_link(sale)
    return if sale.blank?

    platform = sale.shopify_info&.store_id&.present? ? "Shopify" : "WooCommerce"
    link_to sale_shop_link(sale), class: "no-events", target: "_blank", rel: "noopener noreferrer" do
      concat tag.svg(
        xmlns: "http://www.w3.org/2000/svg",
        fill: "none",
        viewBox: "0 0 24 24",
        stroke_width: "1.5",
        stroke: "currentColor",
        class: "size-5"
      ) {
        tag.path(
          stroke_linecap: "round",
          stroke_linejoin: "round",
          d: "M13.5 21v-7.5a.75.75 0 0 1 .75-.75h3a.75.75 0 0 1 .75.75V21m-4.5 0H2.36m11.14 0H18m0 0h3.64m-1.39 0V9.349M3.75 21V9.349m0 0a3.001 3.001 0 0 0 3.75-.615A2.993 2.993 0 0 0 9.75 9.75c.896 0 1.7-.393 2.25-1.016a2.993 2.993 0 0 0 2.25 1.016c.896 0 1.7-.393 2.25-1.015a3.001 3.001 0 0 0 3.75.614m-16.5 0a3.004 3.004 0 0 1-.621-4.72l1.189-1.19A1.5 1.5 0 0 1 5.378 3h13.243a1.5 1.5 0 0 1 1.06.44l1.19 1.189a3 3 0 0 1-.621 4.72M6.75 18h3.75a.75.75 0 0 0 .75-.75V13.5a.75.75 0 0 0-.75-.75H6.75a.75.75 0 0 0-.75.75v3.75c0 .414.336.75.75.75Z"
        )
      }
      concat " Go to #{platform}"
    end
  end
end
