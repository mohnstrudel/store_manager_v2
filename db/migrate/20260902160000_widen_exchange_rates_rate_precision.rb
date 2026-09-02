# frozen_string_literal: true

class WidenExchangeRatesRatePrecision < ActiveRecord::Migration[8.1]
  def change
    # The full ECB history includes pre-redenomination currencies (e.g. Turkish
    # Lira reached ~1,912,400 per EUR in 2004), which overflow decimal(10, 4).
    change_column :exchange_rates, :rate, :decimal, precision: 15, scale: 4
  end
end
