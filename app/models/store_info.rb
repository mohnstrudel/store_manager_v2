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
  include References
  include Validation

  acts_as_taggable_on :tags

  enum :store_name, {
    not_assigned: 0,
    shopify: 1,
    woo: 2
  }, default: :not_assigned

  belongs_to :storable, polymorphic: true

  validates_db_uniqueness_of :store_name, scope: [:storable_type, :storable_id]

  scope :shopify, -> { where(store_name: "shopify") }
  scope :woo, -> { where(store_name: "woo") }

  def self.assignable_store_names
    store_names.keys - ["not_assigned"]
  end

  def update_pull_time
    update(pull_time: Time.zone.now)
  end
end
