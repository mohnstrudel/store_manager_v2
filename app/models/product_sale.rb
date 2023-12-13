# == Schema Information
#
# Table name: product_sales
#
#  id           :bigint           not null, primary key
#  price        :decimal(8, 2)
#  qty          :integer
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  product_id   :bigint           not null
#  sale_id      :bigint           not null
#  variation_id :bigint
#  woo_id       :string
#
class ProductSale < ApplicationRecord
  db_belongs_to :product
  db_belongs_to :sale
  belongs_to :variation, optional: true

  delegate :status, to: :sale

  def item
    (variation.presence || product)
  end

  def item_title
    item.methods.include?(:full_title) ? item.full_title : item.title
  end

  def wip_sales_size
    if variation.present?
      item.product_sales.where.not(variation_id: nil).count { |product_sale|
        Sale.has_wip_status? product_sale.status
      }
    else
      item.product_sales.where(variation_id: nil).count { |product_sale|
        Sale.has_wip_status? product_sale.status
      }
    end
  end

  def purchase_debt
    wip_sales_size - item.purchases.size
  end

  def self.sales_trends
    ProductSale
      .includes(:product, :sale)
      .filter { |ps| Sale.has_wip_status? ps.status }
      .group_by(&:product_id)
      .sort_by { |_, product_sales_group| -product_sales_group.size }
      .first(16)
      .each { |_, product_sales_group|
        product_sales_group.uniq! { |ps| ps.item.id }
      }
      .flatten
      .filter { |el| !el.is_a? Integer }
  end
end
