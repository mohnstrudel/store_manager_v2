# frozen_string_literal: true

class SalesTags::CatalogResource < SalesTagResource
  typelize :number
  attribute :usage_count, &:usage_count
end
