class CreateSales < ActiveRecord::Migration[7.0]
  def change
    create_table :sales do |t|
      t.string :woo_id
      t.string :status
      t.decimal :discount_total, precision: 8, scale: 2
      t.decimal :shipping_total, precision: 8, scale: 2
      t.decimal :total, precision: 8, scale: 2
      t.string :company
      t.string :address_1
      t.string :address_2
      t.string :city
      t.string :state
      t.string :postcode
      t.string :country
      t.string :phone
      t.string :note
      t.belongs_to :customer, null: false, foreign_key: true

      t.timestamps
    end
  end
end
