class AddCounterCashOfPurchasedProductsToProductSales < ActiveRecord::Migration[8.0]
  def up
    add_column :product_sales, :purchased_products_count, :integer, default: 0, null: false

    ProductSale.find_each do |ps|
      ProductSale.reset_counters(ps.id, :purchased_products)
    end
  end

  def down
    remove_column :product_sales, :purchased_products_count
  end
end
