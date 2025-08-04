class AddWooIdToProductSales < ActiveRecord::Migration[7.0]
  def change
    add_column :product_sales, :woo_id, :string
  end
end
