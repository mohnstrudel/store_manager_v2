class AddProductSaleRefToPurchasedProducts < ActiveRecord::Migration[7.1]
  def change
    add_reference :purchased_products, :product_sale, foreign_key: true
  end
end
