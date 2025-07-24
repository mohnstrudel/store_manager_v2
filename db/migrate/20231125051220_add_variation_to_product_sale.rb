class AddVariationToProductSale < ActiveRecord::Migration[7.1]
  def change
    add_reference :product_sales, :variation, foreign_key: true
  end
end
