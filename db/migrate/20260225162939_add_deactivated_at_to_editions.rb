class AddDeactivatedAtToEditions < ActiveRecord::Migration[8.1]
  def change
    add_column :editions, :deactivated_at, :datetime
    add_index :editions, :deactivated_at
  end
end
