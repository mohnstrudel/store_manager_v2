# frozen_string_literal: true

module SaleHelper
  def sale_summary_for_warehouse(sale)
    [sale.customer.full_name, sale.address_1, sale.address_2, sale.postcode, sale.city, sale.country, sale.customer.phone].compact_blank.join(", ")
  end

  def format_sale_status(status)
    status_title = status.titleize

    if Sale.active_status_names.include? status
      content_tag(:span, status_title, class: "text-lime-700")
    else
      content_tag(:span, status_title, class: "text-red-900")
    end
  end
end
