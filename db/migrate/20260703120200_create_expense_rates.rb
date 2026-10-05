class CreateExpenseRates < ActiveRecord::Migration[8.1]
  def change
    create_table :expense_rates do |t|
      t.string :name, null: false
      t.decimal :rate_percent, precision: 5, scale: 2, null: false
      t.boolean :active, default: true, null: false
      t.integer :position

      t.timestamps
    end

    add_index :expense_rates, :name, unique: true
  end
end
