class CreatePayments < ActiveRecord::Migration[7.0]
  def change
    create_table :payments do |t|
      t.decimal :value, precision: 8, scale: 2

      t.timestamps
    end
  end
end
