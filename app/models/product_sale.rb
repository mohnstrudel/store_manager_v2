# == Schema Information
#
# Table name: product_sales
#
#  id         :bigint           not null, primary key
#  price      :decimal(8, 2)
#  qty        :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  product_id :bigint           not null
#  sale_id    :bigint           not null
#  woo_id     :string
#
class ProductSale < ApplicationRecord
  belongs_to :product
  belongs_to :sale

  delegate :full_title, to: :product
  delegate :status, to: :sale

  def self.sales_trends
    # 1. Get products that have been ordered
    # 2. Exclude products that we purchased
    # 3. Filter out by status because we only want new orders
    # 4. Group them by product to find the most ordered
    # 5. Sort by quantity and grab first chunck
    # Also, 16 — is just a number, no hidden magic behind it
    ProductSale
      .joins(:product)
      .where.not(product_id: Product.joins(:purchases))
      .select { |product_sale|
        Sale.STATUS_NEW.include? product_sale.status
      }
      .group_by(&:product_id)
      .sort_by { |_product_id, product_sales| -product_sales.size }
      .first(16)
  end
end
