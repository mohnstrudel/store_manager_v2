class AddTrackingNumberToPurchaseItems < ActiveRecord::Migration[8.0]
  def change
    add_column :purchase_items, :tracking_number, :string
  end
end
