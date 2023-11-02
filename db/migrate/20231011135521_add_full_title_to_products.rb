class AddFullTitleToProducts < ActiveRecord::Migration[7.1]
  def change
    add_column :products, :full_title, :string
  end
end
