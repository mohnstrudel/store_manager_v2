class CreateMedia < ActiveRecord::Migration[8.1]
  def change
    create_table :media do |t|
      t.string :mediaable_type, null: false
      t.bigint :mediaable_id, null: false
      t.integer :position, default: 0, null: false
      t.string :alt, default: "", null: false

      t.timestamps
    end

    add_index :media, [:mediaable_type, :mediaable_id]
    add_index :media, :position
  end
end
