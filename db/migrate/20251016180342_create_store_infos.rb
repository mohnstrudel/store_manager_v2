class CreateStoreInfos < ActiveRecord::Migration[8.0]
  def change
    create_table :store_infos do |t|
      t.integer :name, default: 0, null: false
      t.integer :push_status, default: 0, null: true
      t.integer :pull_status, default: 0, null: true
      t.timestamp :push_time, null: true
      t.timestamp :pull_time, null: true
      t.string :page_url, null: true
      t.string :store_product_id, null: true
      t.references :product, null: false, foreign_key: true

      t.timestamps
    end
  end
end
