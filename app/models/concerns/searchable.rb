# frozen_string_literal: true

module Searchable
  extend ActiveSupport::Concern

  class_methods do
    def set_search_scope(scope_name = :search, **options)
      using = options[:using]&.deep_dup || {}
      using[:tsearch] ||= {}
      using[:tsearch][:prefix] = true

      pg_search_scope scope_name, **options.merge(using:)
    end
  end

  included do
    include PgSearch::Model

    scope :search_by, ->(query) { query.present? ? search(query) : all }
  end
end
