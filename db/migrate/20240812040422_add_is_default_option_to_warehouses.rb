class AddIsDefaultOptionToWarehouses < ActiveRecord::Migration[7.1]
  def change
    add_column :warehouses, :is_default, :boolean, default: false, null: false
    add_index :warehouses, :is_default, unique: true, where: "is_default = true"
  end
end
