class AddSkuToProducts < ActiveRecord::Migration[7.1]
  def change
    add_column :products, :sku, :string
    add_index :products, :sku, unique: true
  end
end
