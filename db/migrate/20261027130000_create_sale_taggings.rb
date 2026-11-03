# frozen_string_literal: true

class CreateSaleTaggings < ActiveRecord::Migration[8.1]
  def change
    create_table :sale_taggings do |t| # rubocop:disable Rails/CreateTableWithTimestamps -- join rows carry no state of their own
      t.references :sale, null: false, foreign_key: {on_delete: :cascade}
      t.references :sales_tag, null: false, foreign_key: {on_delete: :cascade}
    end

    add_index :sale_taggings, %i[sale_id sales_tag_id], unique: true
  end
end
