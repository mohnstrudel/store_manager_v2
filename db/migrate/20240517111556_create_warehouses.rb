class CreateWarehouses < ActiveRecord::Migration[7.1]
  def change
    create_table :warehouses do |t|
      t.string :name
      t.string :external_name
      t.string :container_tracking_number
      t.string :courier_tracking_url
      t.string :cbm

      t.timestamps
    end
  end
end
