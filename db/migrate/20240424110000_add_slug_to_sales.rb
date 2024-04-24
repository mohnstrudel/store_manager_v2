class AddSlugToSales < ActiveRecord::Migration[7.1]
  def change
    add_column :sales, :slug, :string
    add_index :sales, :slug, unique: true
  end
end
