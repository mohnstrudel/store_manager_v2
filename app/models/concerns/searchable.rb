module Searchable
  extend ActiveSupport::Concern

  class_methods do
    def set_search_scope(scope_name = :search, **options)
      pg_search_scope scope_name, **options
    end
  end

  included do
    include PgSearch::Model
    scope :search_by, ->(query) { query.present? ? search(query) : all }
  end
end
