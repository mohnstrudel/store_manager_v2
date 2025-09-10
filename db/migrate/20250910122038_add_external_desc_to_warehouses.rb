class AddExternalDescToWarehouses < ActiveRecord::Migration[8.0]
  def change
    add_column :warehouses, :external_desc, :string
  end
end
