# frozen_string_literal: true

# == Schema Information
#
# Table name: sale_items
#
#  id                   :bigint           not null, primary key
#  price                :decimal(8, 2)
#  purchase_items_count :integer          default(0), not null
#  qty                  :integer
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  edition_id           :bigint
#  product_id           :bigint           not null
#  sale_id              :bigint           not null
#  shopify_id           :string
#  woo_id               :string
#
class SaleItem < ApplicationRecord
  # TODO: Remove after merging the Auth PR #141
  self.ignored_columns += ["purchased_products_count"]
  attr_accessor :_destroy

  include HasAuditNotifications
  include Linkability
  include Listing
  include Shopable
  include Titling

  audited associated_with: :sale
  validate :validate_unique_woo_store_id

  db_belongs_to :product, inverse_of: :sale_items
  db_belongs_to :sale, inverse_of: :sale_items
  belongs_to :edition, optional: true, inverse_of: :sale_items

  has_many :purchase_items, dependent: :nullify, inverse_of: :sale_item

  private

  def validate_unique_woo_store_id
    return if woo_store_id.blank?

    existing_store_info = StoreInfo
      .woo
      .where(storable_type: self.class.name, store_id: woo_store_id)
      .where.not(storable_id: id)
      .exists?

    errors.add(:woo_store_id, "has already been taken") if existing_store_info
  end
end
