# frozen_string_literal: true

class MoveShapesToProducts < ActiveRecord::Migration[8.1]
  class ProductRecord < ActiveRecord::Base
    self.table_name = "products"
  end

  class ShapeRecord < ActiveRecord::Base
    self.table_name = "shapes"
  end

  DEFAULT_SHAPE = "Statue"

  def up
    add_column :products, :shape, :string, default: DEFAULT_SHAPE

    ProductRecord.reset_column_information
    ShapeRecord.reset_column_information

    ProductRecord.find_each do |product|
      product.update_columns(shape: ShapeRecord.find_by(id: product.shape_id)&.title.presence || DEFAULT_SHAPE)
    end

    change_column_null :products, :shape, false
    add_check_constraint :products, "shape IN ('Statue', 'Bust')", name: "products_shape_allowed_values"

    remove_foreign_key :products, :shapes
    remove_index :products, :shape_id
    remove_column :products, :shape_id
    drop_table :shapes
  end

  def down
    create_table :shapes do |t|
      t.string :title

      t.timestamps
    end

    ShapeRecord.reset_column_information
    ProductRecord.reset_column_information

    add_reference :products, :shape, null: true, foreign_key: true

    ProductRecord.select(:id, :shape).find_each do |product|
      shape = ShapeRecord.find_or_create_by!(title: product.shape.presence || DEFAULT_SHAPE)
      product.update_columns(shape_id: shape.id)
    end

    change_column_null :products, :shape_id, false
    remove_check_constraint :products, name: "products_shape_allowed_values"
    remove_column :products, :shape
  end
end
