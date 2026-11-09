# frozen_string_literal: true

class SalesTags::DetailResource < SalesTagResource
  typelize "Array<SalesTagsSale>"
  attribute :sales do |sales_tag|
    SalesTags::SaleResource.new(sales_tag.sales.with_customer_and_item_products.sorted_by("newest")).serializable_hash
  end
end
