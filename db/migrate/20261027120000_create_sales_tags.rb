# frozen_string_literal: true

class CreateSalesTags < ActiveRecord::Migration[8.1]
  def change
    create_table :sales_tags do |t|
      t.string :name, null: false
      t.string :normalized_name, null: false
      t.string :color, null: false, default: "gray"
      t.timestamps
    end

    add_index :sales_tags, :normalized_name, unique: true
  end
end
