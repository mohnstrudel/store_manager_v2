class AddSlugToSuppliers < ActiveRecord::Migration[7.1]
  def change
    add_column :suppliers, :slug, :string
    add_index :suppliers, :slug, unique: true
  end
end
