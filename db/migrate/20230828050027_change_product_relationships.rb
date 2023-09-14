class ChangeProductRelationships < ActiveRecord::Migration[7.0]
  def change
    remove_reference :products, :size, foreign_key: true
    remove_reference :products, :version, foreign_key: true
    remove_reference :products, :color, foreign_key: true
    remove_reference :products, :supplier, foreign_key: true
    remove_reference :products, :brand, foreign_key: true

    create_table :product_sizes do |t|
      t.belongs_to :product, foreign_key: true
      t.belongs_to :size, foreign_key: true
      t.timestamps
    end

    create_table :product_versions do |t|
      t.belongs_to :product, foreign_key: true
      t.belongs_to :version, foreign_key: true
      t.timestamps
    end

    create_table :product_colors do |t|
      t.belongs_to :product, foreign_key: true
      t.belongs_to :color, foreign_key: true
      t.timestamps
    end

    create_table :product_suppliers do |t|
      t.belongs_to :product, foreign_key: true
      t.belongs_to :supplier, foreign_key: true
      t.timestamps
    end

    create_table :product_brands do |t|
      t.belongs_to :product, foreign_key: true
      t.belongs_to :brand, foreign_key: true
      t.timestamps
    end
  end
end
