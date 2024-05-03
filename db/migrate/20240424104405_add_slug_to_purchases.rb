class AddSlugToPurchases < ActiveRecord::Migration[7.1]
  def change
    add_column :purchases, :slug, :string
    add_index :purchases, :slug, unique: true
  end
end
