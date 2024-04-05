class RemoveTitleFromVariations < ActiveRecord::Migration[7.1]
  def change
    remove_column :variations, :title, :string
  end
end
