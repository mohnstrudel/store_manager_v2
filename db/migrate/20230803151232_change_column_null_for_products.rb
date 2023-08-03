class ChangeColumnNullForProducts < ActiveRecord::Migration[7.0]
  def change
    change_column_null :products, :size_id, true
    change_column_null :products, :color_id, true
    change_column_null :products, :version_id, true
  end
end
