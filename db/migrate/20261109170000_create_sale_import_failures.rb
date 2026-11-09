# frozen_string_literal: true

class CreateSaleImportFailures < ActiveRecord::Migration[8.1]
  def change
    create_table :sale_import_failures do |t|
      t.string :store_name, null: false
      t.string :store_order_id, null: false
      t.references :sale, foreign_key: {on_delete: :nullify}
      t.text :message, null: false
      t.string :sentry_event_id
      t.integer :failure_count, null: false, default: 0
      t.datetime :first_failed_at, null: false
      t.datetime :last_failed_at, null: false
      t.datetime :resolved_at
      t.timestamps
    end

    add_index :sale_import_failures, %i[store_name store_order_id], unique: true
  end
end
