class AddPublishedAtToProducts < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :published_at, :datetime
    add_index :products, :published_at
  end
end
