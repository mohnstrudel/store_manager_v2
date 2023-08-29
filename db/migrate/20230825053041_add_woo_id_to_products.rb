class AddWooIdToProducts < ActiveRecord::Migration[7.0]
  def change
    add_column :products, :woo_id, :string
  end
end
