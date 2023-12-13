class CreateVariations < ActiveRecord::Migration[7.1]
  def change
    create_table :variations do |t|
      t.string :title
      t.string :woo_id
      t.references :size, foreign_key: true
      t.references :version, foreign_key: true
      t.references :color, foreign_key: true
      t.references :product, null: false, foreign_key: true

      t.timestamps
    end
  end
end
