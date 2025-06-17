class RemoveTrackingNumberFromPurchaseItems < ActiveRecord::Migration[7.1]
  def change
    remove_column :purchase_items, :tracking_number, :string
  end
end
