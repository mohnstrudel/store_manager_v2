# frozen_string_literal: true

module Searchable
  extend ActiveSupport::Concern

  class_methods do
    def search_by(query)
      return all if query.blank?

      if reflect_on_association(:store_infos)
        result_by_store_id = search_by_store_id(query)
        return result_by_store_id if result_by_store_id.exists?
      end

      search(query)
    end

    def set_search_scope(scope_name = :search, **options)
      using = options[:using]&.deep_dup || {}
      using[:tsearch] ||= {}
      using[:tsearch][:prefix] = true

      pg_search_scope scope_name, **options.merge(using:)
    end

    private

    def search_by_store_id(query)
      joins(:store_infos)
        .where(
          "store_infos.store_id = :query OR split_part(store_infos.store_id, '/', array_length(string_to_array(store_infos.store_id, '/'), 1)) = :query",
          query:
        )
        .distinct
    end
  end

  included do
    include PgSearch::Model
  end
end
