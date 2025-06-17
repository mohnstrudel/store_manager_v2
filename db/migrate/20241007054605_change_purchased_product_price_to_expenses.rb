class ChangePurchaseItemPriceToExpenses < ActiveRecord::Migration[7.2]
  def change
    rename_column :purchase_items, :price, :expenses
  end
end
