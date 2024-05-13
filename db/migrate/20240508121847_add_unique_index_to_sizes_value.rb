class AddUniqueIndexToSizesValue < ActiveRecord::Migration[7.1]
  def change
    add_index :sizes, :value, unique: true
  end
end
