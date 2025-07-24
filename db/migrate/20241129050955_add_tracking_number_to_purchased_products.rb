class AddTrackingNumberToPurchasedProducts < ActiveRecord::Migration[8.0]
  def change
    add_column :purchased_products, :tracking_number, :string
  end
end
