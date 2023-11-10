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
  delegate :purchases, to: :product

  def self.sales_trends
    # Get a list of products that have been sold but not purchased enough:
    # - Get products that have been sold
    # - Exclude irrelevant ones, e.g. completed or failed
    # - Group by product and sort by the number of missing purchases
    # - Grab a first chunck of 16
    ProductSale
      .includes(:product, :sale)
      .select { |product_sale|
        Sale.STATUS_NEW.include? product_sale.status
      }
      .group_by(&:product_id)
      .sort_by { |_product_id, product_sales| -product_sales.size }
      .first(16)
  end
end
