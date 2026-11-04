# frozen_string_literal: true

class SalesTags::SaleResource < ApplicationResource
  typelize_from Sale

  attributes :id

  typelize :string
  attribute :path do |sale|
    sale_path(sale)
  end

  typelize :string
  attribute :label, &:link_title

  typelize "Array<{ id: number; title: string | null; product_thumb_url: string | null }>"
  attribute :items do |sale|
    sale.sale_items.map { |item| {id: item.id, title: item.title, product_thumb_url: thumb_url(item.product)} }
  end
end
