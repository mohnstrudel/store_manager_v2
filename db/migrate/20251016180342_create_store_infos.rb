class CreateStoreInfos < ActiveRecord::Migration[8.0]
  def change
    create_table :store_infos do |t|
      t.integer :store_name, default: 0, null: false
      t.timestamp :push_time, null: true
      t.timestamp :pull_time, null: true
      t.string :slug, null: true
      t.string :store_id, null: true
      t.decimal :price, precision: 8, scale: 2, default: 0.0, null: false

      t.references :storable, polymorphic: true, null: false, index: true

      t.timestamps
    end

    add_index :store_infos,
      [:store_name, :storable_type, :storable_id],
      unique: true,
      name: "index_store_infos_on_unique_store_per_storable"
  end
end
