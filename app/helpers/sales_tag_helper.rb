# frozen_string_literal: true

module SalesTagHelper
  def sales_tag_catalog_props(sales_tag)
    sales_tag_props(sales_tag).merge(usage_count: sales_tag.usage_count)
  end

  def sales_tag_props(sales_tag)
    {id: sales_tag.id, name: sales_tag.name, color: sales_tag.color}
  end

  def sales_tag_detail_props(sales_tag)
    sales = sales_tag.sales.for_link_title.sorted_by("newest")

    sales_tag_props(sales_tag).merge(sales: sales.map { |sale| sales_tag_sale_props(sale) })
  end

  private

  def sales_tag_sale_props(sale)
    {
      id: sale.id,
      path: sale_path(sale),
      label: sale.link_title,
      items: sale.sale_items.map { |item| {id: item.id, title: item.title, product_thumb_url: thumb_url(item.product)} }
    }
  end
end
