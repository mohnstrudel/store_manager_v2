class AddPositionToWarehouses < ActiveRecord::Migration[8.0]
  def change
    add_column :warehouses, :position, :integer, null: false, default: 1

    reversible do |dir|
      dir.up do
        Warehouse.find_each.with_index do |warehouse, index|
          warehouse.update_column(:position, index + 1)
        end
      end
    end

    add_index :warehouses, :position, unique: true
  end
end
