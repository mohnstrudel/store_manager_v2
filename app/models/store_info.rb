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

  enum :store_name, {
    not_assigned: 0,
    shopify: 1,
    woo: 2
  }, default: :not_assigned

  belongs_to :storable, polymorphic: true

  scope :shopify, -> { where(store_name: "shopify") }
  scope :woo, -> { where(store_name: "woo") }

  validates_db_uniqueness_of :store_name, scope: [:storable_type, :storable_id]

  def product_url(handle = nil)
    handle ||= slug
    case store_name
    when "shopify"
      "https://handsomecake.com/products/#{handle}"
    when "woo"
      "https://store.handsomecake.com/product/#{handle}"
    end
  end

  # Store ID without GID prefix
  def id_short
    return if store_id.blank?

    shopify_api_category_name = external_name_for(storable_type)
    store_id.gsub("gid://shopify/#{shopify_api_category_name}/", "")
  end

  def update_pull_time
    update(pull_time: Time.zone.now)
  end

  private

  def external_name_for(our_name)
    case our_name
    when "Sale"
      "Order"
    when "Edition"
      "ProductVariant"
    else
      our_name
    end
  end
end
