# frozen_string_literal: true

class CreateSaleAddresses < ActiveRecord::Migration[8.1]
  def change
    create_table :sale_addresses do |t|
      t.references :sale, null: false, foreign_key: true
      t.integer :kind, null: false
      t.string :first_name
      t.string :last_name
      t.string :email
      t.string :phone
      t.string :company
      t.string :address_1
      t.string :address_2
      t.string :city
      t.string :state
      t.string :postcode
      t.string :country

      t.timestamps
    end

    add_index :sale_addresses, [:sale_id, :kind], unique: true
  end
end
