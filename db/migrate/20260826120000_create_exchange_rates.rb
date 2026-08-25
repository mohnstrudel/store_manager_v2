# frozen_string_literal: true

class CreateExchangeRates < ActiveRecord::Migration[8.1]
  def change
    create_table :exchange_rates do |t|
      t.date :date, null: false
      t.string :currency, null: false
      t.decimal :rate, precision: 10, scale: 4, null: false
      t.datetime :fetched_at, null: false

      t.timestamps
    end

    add_index :exchange_rates, [:currency, :date], unique: true
    add_check_constraint :exchange_rates, "rate > 0", name: "exchange_rates_positive_rate"
  end
end
