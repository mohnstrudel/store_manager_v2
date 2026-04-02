# frozen_string_literal: true

module StoreInfo::Validation
  extend ActiveSupport::Concern

  included do
    attr_accessor :_destroy

    validate :store_name_must_be_unique_within_storable
    validate :storable_store_info_limit
  end

  def marked_for_editing_destruction?
    ActiveModel::Type::Boolean.new.cast(@_destroy) || marked_for_destruction? || destroyed?
  end

  private

  def store_name_must_be_unique_within_storable
    return if marked_for_editing_destruction? || store_name.blank? || not_assigned?
    return unless active_sibling_store_infos.any? { |store_info| store_info.store_name == store_name }

    errors.add(:store_name, "has already been taken")
  end

  def storable_store_info_limit
    return unless limited_store_info_storable?

    active_store_infos = active_sibling_store_infos.dup
    active_store_infos << self unless marked_for_editing_destruction?

    return unless active_store_infos.count > self.class.assignable_store_names.count

    errors.add(:base, "Too many store connections for #{storable_type}")
  end

  def limited_store_info_storable?
    storable&.respond_to?(:shopify_info) && storable.respond_to?(:woo_info)
  end

  def active_sibling_store_infos
    (persisted_sibling_store_infos + in_memory_sibling_store_infos).uniq.reject do |store_info|
      same_store_info?(store_info) || store_info.marked_for_editing_destruction?
    end
  end

  def storable_store_infos_association?
    storable&.class&.reflect_on_association(:store_infos).present?
  end

  def persisted_sibling_store_infos
    relation = self.class.where(storable: storable)
    relation = relation.where.not(id: id) if id.present?
    relation.to_a
  end

  def in_memory_sibling_store_infos
    return [] unless storable_store_infos_association?

    storable.association(:store_infos).target
  end

  def same_store_info?(store_info)
    return true if store_info.equal?(self)
    return false if store_info.id.blank? || id.blank?

    store_info.id == id
  end
end
