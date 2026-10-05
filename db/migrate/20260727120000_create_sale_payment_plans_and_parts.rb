# frozen_string_literal: true

class CreateSalePaymentPlansAndParts < ActiveRecord::Migration[8.0]
  def change
    create_table :sale_payment_plans do |t|
      t.string :provider, null: false
      t.string :external_id, null: false
      t.string :external_origin_order_id
      t.references :origin_sale, foreign_key: {to_table: :sales}
      t.string :kind, null: false
      t.string :status
      t.integer :expected_parts, null: false
      t.decimal :deposit_percent, precision: 5, scale: 2
      t.decimal :projected_total, precision: 12, scale: 2
      t.string :currency
      t.datetime :next_due_at
      t.datetime :synced_at, null: false
      t.timestamps
    end

    add_index :sale_payment_plans, [:provider, :external_id], unique: true
    add_index :sale_payment_plans, :external_origin_order_id

    create_table :sale_payment_parts do |t|
      t.references :sale_payment_plan, null: false, foreign_key: true
      t.string :provider_part_id
      t.integer :sequence, null: false
      t.string :external_order_id
      t.references :sale, foreign_key: true
      t.decimal :amount, precision: 12, scale: 2
      t.string :currency
      t.datetime :due_at
      t.datetime :provider_completed_at
      t.boolean :active, null: false, default: true
      t.timestamps
    end

    add_index :sale_payment_parts, [:sale_payment_plan_id, :sequence], unique: true
    add_index :sale_payment_parts,
      [:sale_payment_plan_id, :provider_part_id],
      unique: true,
      where: "provider_part_id IS NOT NULL"
    add_index :sale_payment_parts, :external_order_id
  end
end
