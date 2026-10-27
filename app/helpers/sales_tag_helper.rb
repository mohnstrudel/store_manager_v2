# frozen_string_literal: true

module SalesTagHelper
  def sales_tag_catalog_props(sales_tag)
    sales_tag_props(sales_tag).merge(usage_count: 0)
  end

  def sales_tag_props(sales_tag)
    {id: sales_tag.id, name: sales_tag.name, color: sales_tag.color}
  end
end
