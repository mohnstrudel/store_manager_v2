class RemoveTrackingNumberFromPurchasedProducts < ActiveRecord::Migration[7.1]
  def change
    remove_column :purchased_products, :tracking_number, :string
  end
end
