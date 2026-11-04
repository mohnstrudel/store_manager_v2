# frozen_string_literal: true

class SalesTags::IndexResource < ApplicationResource
  typelize "Array<SalesTagsCatalog>"
  attribute :sales_tags do |page|
    SalesTags::CatalogResource.new(page.fetch(:sales_tags)).serializable_hash
  end

  typelize({id: "number | null", name: :string, color: "SalesTag['color']"}, nullable: true)
  attribute :sales_tag do |page|
    form = page.fetch(:form)
    {id: form.id, name: form.name, color: form.color} if form
  end

  typelize "SalesTagsDetail | null"
  attribute :sales_tag_detail do |page|
    detail = page.fetch(:detail)
    SalesTags::DetailResource.new(detail).serializable_hash if detail
  end

  typelize "Array<SalesTag['color']>"
  attribute :tag_colors do |_page|
    SalesTag::COLORS
  end

  typelize :boolean
  attribute :can_manage_sales_tags do |page|
    page.fetch(:can_manage_sales_tags)
  end
end
