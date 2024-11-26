class CreateWarehouseTransitions < ActiveRecord::Migration[7.2]
  def change
    create_table :warehouse_transitions do |t|
      t.references :from_warehouse, foreign_key: {to_table: :warehouses}
      t.references :to_warehouse, foreign_key: {to_table: :warehouses}
      t.references :notification, null: false, foreign_key: true

      t.timestamps
    end

    add_index :warehouse_transitions,
      [:notification_id, :from_warehouse_id, :to_warehouse_id],
      unique: true,
      name: "index_warehouse_transitions_uniqueness"
  end
end
