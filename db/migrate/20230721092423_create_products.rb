class CreateProducts < ActiveRecord::Migration[7.0]
  def change
    create_table :products do |t|
      t.string :title
      t.belongs_to :supplier, null: false, foreign_key: true
      t.belongs_to :brand, null: false, foreign_key: true
      t.belongs_to :franchise, null: false, foreign_key: true
      t.belongs_to :size, null: false, foreign_key: true
      t.belongs_to :color, null: false, foreign_key: true
      t.belongs_to :version, null: false, foreign_key: true
      t.belongs_to :shape, null: false, foreign_key: true

      t.timestamps
    end
  end
end
