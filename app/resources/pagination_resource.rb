# frozen_string_literal: true

class PaginationResource < ApplicationResource
  typelize current_page: :number, total_pages: :number, total_count: :number, limit: :number
  attributes :current_page, :total_pages, :total_count, :limit

  def self.for(collection)
    new({
      current_page: collection.current_page,
      total_pages: collection.total_pages,
      total_count: collection.total_count,
      limit: collection.limit_value
    }).serializable_hash
  end
end
