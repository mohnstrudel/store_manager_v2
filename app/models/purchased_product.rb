# == Schema Information
#
# Table name: purchased_products
#
#  id                  :bigint           not null, primary key
#  expenses            :decimal(8, 2)
#  height              :integer
#  length              :integer
#  shipping_price      :decimal(8, 2)
#  tracking_number     :string
#  weight              :integer
#  width               :integer
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  product_sale_id     :bigint
#  purchase_id         :bigint
#  shipping_company_id :bigint
#  warehouse_id        :bigint           not null
#
class PurchasedProduct < ApplicationRecord
  include HasPreviewImages
  include PgSearch::Model

  pg_search_scope :search,
    associated_against: {
      product: [:full_title]
    },
    using: {
      tsearch: {prefix: true}
    }

  db_belongs_to :warehouse
  db_belongs_to :purchase

  belongs_to :product_sale, optional: true
  has_one :sale, through: :product_sale

  has_one :product, through: :purchase

  belongs_to :shipping_company, optional: true

  validates :tracking_number,
    presence: true,
    if: -> { shipping_company_id.present? }

  validates :shipping_company_id,
    presence: true,
    if: -> { tracking_number.present? }

  scope :ordered_by_updated_date, -> { order(updated_at: :desc) }

  def name
    purchase.full_title
  end

  def cost
    (price || 0) + (purchase.item_price || 0)
  end

  def self.unlinked_records(product_id)
    where(product_sale_id: nil)
      .joins(:purchase)
      .where(
        purchase: {product_id:}
      )
  end

  def self.bulk_move_to_warehouse(ids, destination_id)
    purchased_products = where(id: ids)

    ids_grouped_by_warehouse = purchased_products
      .group_by(&:warehouse_id)
      .transform_values { |purchased_products|
        purchased_products.pluck(:id)
      }

    moved_count = purchased_products.update_all(warehouse_id: destination_id)

    return moved_count if moved_count == 0

    ids_grouped_by_warehouse.each do |from_id, purchased_product_ids|
      Notification.dispatch(
        event: Notification.event_types[:warehouse_changed],
        context: {
          purchased_product_ids:,
          from_id:,
          to_id: destination_id
        }
      )
    end

    moved_count
  end
end
