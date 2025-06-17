class AddWooIdToSaleItems < ActiveRecord::Migration[7.0]
  def change
    add_column :sale_items, :woo_id, :string
  end
end
