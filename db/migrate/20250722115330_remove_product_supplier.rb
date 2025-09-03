class RemoveProductSupplier < ActiveRecord::Migration[8.0]
  def up
    drop_table :product_suppliers
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "This migration cannot be reverted because it destroys data."
  end
end
