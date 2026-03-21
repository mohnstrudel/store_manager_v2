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

  include HasAuditNotifications
  include Linkability
  include Listing

  audited associated_with: :sale
  validates_db_uniqueness_of :woo_id, allow_nil: true

  db_belongs_to :product, inverse_of: :sale_items
  db_belongs_to :sale, inverse_of: :sale_items
  belongs_to :edition, optional: true, inverse_of: :sale_items
  has_many :purchase_items, dependent: :nullify, inverse_of: :sale_item

  def title
    edition_id.present? ? "#{product.full_title} → #{edition.title}" : product.full_title
  end

  def build_title_for_select
    status = sale.status&.titleize
    email = sale.customer.email
    pretty_sale_id = "Sale ID: #{sale_id}"
    pretty_woo_id = woo_id && "Woo ID: #{woo_id}"

    [id, status, title, email, pretty_sale_id, pretty_woo_id].compact.join(" | ")
  end
end
