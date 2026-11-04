# frozen_string_literal: true

class SalesTags::DetailResource < SalesTagResource
  typelize "Array<SalesTagsSale>"
  attribute :sales do |sales_tag|
    SalesTags::SaleResource.new(sales_tag.sales.for_link_title.sorted_by("newest")).serializable_hash
  end
end
