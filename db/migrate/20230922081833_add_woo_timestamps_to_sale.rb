class AddWooTimestampsToSale < ActiveRecord::Migration[7.0]
  def change
    change_table :sales, bulk: true do |t|
      t.datetime :woo_created_at
      t.datetime :woo_updated_at
    end
  end
end
