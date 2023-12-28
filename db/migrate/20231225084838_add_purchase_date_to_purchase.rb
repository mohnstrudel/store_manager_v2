class AddPurchaseDateToPurchase < ActiveRecord::Migration[7.1]
  def change
    add_column :purchases, :purchase_date, :datetime
  end
end
