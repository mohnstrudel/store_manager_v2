class AddSyncedToPurchase < ActiveRecord::Migration[7.1]
  def change
    add_column :purchases, :synced, :string
  end
end
