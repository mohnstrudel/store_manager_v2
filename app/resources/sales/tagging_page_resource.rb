# frozen_string_literal: true

class Sales::TaggingPageResource < ApplicationResource
  typelize "Array<SalesTag>"
  attribute :tag_options do |page|
    SalesTagResource.new(page.fetch(:tag_catalog).sort_by(&:sort_key)).serializable_hash
  end

  typelize "Array<SalesTag['color']>"
  attribute :tag_colors do |_page|
    SalesTag::COLORS
  end

  typelize :boolean
  attribute :can_tag_sales do |page|
    page.fetch(:can_tag_sales)
  end
end
