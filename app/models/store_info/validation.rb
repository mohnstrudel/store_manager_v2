# frozen_string_literal: true

module StoreInfo::Validation
  extend ActiveSupport::Concern

  included do
    attr_accessor :_destroy

    validate :store_name_must_be_unique_within_storable
    validate :storable_store_info_limit
  end

  def should_be_removed?
    ActiveModel::Type::Boolean.new.cast(@_destroy) || marked_for_destruction? || destroyed?
  end

  private

  def store_name_must_be_unique_within_storable
    return if should_be_removed? || store_name.blank? || not_assigned?
    return unless active_sibling_store_infos.any? { |store_info| store_info.store_name == store_name }

    errors.add(:store_name, :taken)
  end

  def storable_store_info_limit
    return unless limited_store_info_storable?

    active_store_infos = active_sibling_store_infos.reject(&:not_assigned?).dup
    active_store_infos << self unless should_be_removed?
    active_store_infos.reject!(&:not_assigned?)

    return unless active_store_infos.count > self.class.assignable_store_names.count

    errors.add(:base, :too_many_store_connections, storable_type:)
  end

  def limited_store_info_storable?
    storable&.respond_to?(:shopify_info) && storable.respond_to?(:woo_info)
  end

  def active_sibling_store_infos
    (persisted_sibling_store_infos + in_memory_sibling_store_infos).uniq.reject do |store_info|
      same_store_info?(store_info) || store_info.should_be_removed?
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
