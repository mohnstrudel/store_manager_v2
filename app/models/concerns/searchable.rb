# frozen_string_literal: true

module Searchable
  extend ActiveSupport::Concern

  class_methods do
    def search_by(query)
      return all if query.blank?

      if store_id_searchable?
        result_by_store_id = search_by_store_id(query)
        return result_by_store_id if result_by_store_id.exists?
      end

      search(query)
    end

    def set_search_scope(scope_name = :search, **options)
      self.searchable_store_id_associations = Array(options.delete(:store_id_associations))

      using = options[:using]&.deep_dup || {}
      using[:tsearch] ||= {}
      using[:tsearch][:prefix] = true

      pg_search_scope scope_name, **options.merge(using:)
    end

    private

    def store_id_searchable?
      reflect_on_association(:store_infos) || searchable_store_id_associations.any?
    end

    def search_by_store_id(query)
      matching_relations = [where(id: store_info_matching_ids_for(:store_infos, query))]
      searchable_store_id_associations.each do |association_name|
        matching_relations << where(id: store_info_matching_ids_for({association_name => :store_infos}, query))
      end

      matching_relations.reduce(none, &:or)
    end

    def store_info_matching_ids_for(join_target, query)
      joins(join_target)
        .where(
          "store_infos.store_id = :query OR split_part(store_infos.store_id, '/', array_length(string_to_array(store_infos.store_id, '/'), 1)) = :query",
          query:
        )
        .select(:id)
    end
  end

  included do
    include PgSearch::Model
    class_attribute :searchable_store_id_associations, default: []
  end
end
