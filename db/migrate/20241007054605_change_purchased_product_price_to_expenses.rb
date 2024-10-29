class ChangePurchasedProductPriceToExpenses < ActiveRecord::Migration[7.2]
  def change
    rename_column :purchased_products, :price, :expenses
  end
end
