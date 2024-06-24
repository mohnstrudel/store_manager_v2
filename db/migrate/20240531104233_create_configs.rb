class CreateConfigs < ActiveRecord::Migration[7.1]
  def change
    create_table :configs do |t|
      t.integer :sales_hook_status, default: 0

      t.timestamps
    end
  end
end
