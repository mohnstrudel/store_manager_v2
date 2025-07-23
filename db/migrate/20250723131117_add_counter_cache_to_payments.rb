class AddCounterCacheToPayments < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_column :purchases, :payments_count, :integer, default: 0, null: false
    add_index :purchases, :payments_count, algorithm: :concurrently
  end
end
