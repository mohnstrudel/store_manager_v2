# frozen_string_literal: true

# == Schema Information
#
# Table name: store_infos
#
#  id             :bigint           not null, primary key
#  alt_text       :string
#  checksum       :string
#  ext_created_at :datetime
#  ext_updated_at :datetime
#  pull_time      :datetime
#  push_time      :datetime
#  slug           :string
#  storable_type  :string           not null
#  store_name     :integer          default("not_assigned"), not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  storable_id    :bigint           not null
#  store_id       :string
#
class StoreInfo < ApplicationRecord
  # TODO: Remove after deploy 99
  self.ignored_columns += ["price"]

  include References

  acts_as_taggable_on :tags

  enum :store_name, {
    not_assigned: 0,
    shopify: 1,
    woo: 2
  }, default: :not_assigned

  belongs_to :storable, polymorphic: true

  validates_db_uniqueness_of :store_name, scope: [:storable_type, :storable_id]
  validate :storable_store_info_limit

  scope :shopify, -> { where(store_name: "shopify") }
  scope :woo, -> { where(store_name: "woo") }

  def self.assignable_store_names
    store_names.keys - ["not_assigned"]
  end

  def update_pull_time
    update(pull_time: Time.zone.now)
  end

  private

  def storable_store_info_limit
    return unless limited_store_info_storable?

    active_store_infos = persisted_sibling_store_infos + in_memory_new_sibling_store_infos
    active_store_infos << self unless marked_for_destruction? || destroyed?

    return unless active_store_infos.count > self.class.assignable_store_names.count

    errors.add(:base, "Too many store connections for #{storable_type}")
  end

  def limited_store_info_storable?
    storable&.respond_to?(:shopify_info) && storable.respond_to?(:woo_info)
  end

  def persisted_sibling_store_infos
    self.class.where(storable: storable).where.not(id: id).to_a
  end

  def in_memory_new_sibling_store_infos
    return [] unless storable.respond_to?(:association)

    association = storable.association(:store_infos)
    return [] unless association.loaded?

    association.target.select do |store_info|
      store_info != self && !store_info.persisted? && !store_info.marked_for_destruction? && !store_info.destroyed?
    end
  end
end
