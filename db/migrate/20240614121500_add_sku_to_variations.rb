class AddSkuToVariations < ActiveRecord::Migration[7.1]
  def change
    add_column :variations, :sku, :string
    add_index :variations, :sku, unique: true
  end
end
