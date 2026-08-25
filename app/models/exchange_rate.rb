# frozen_string_literal: true

# == Schema Information
#
# Table name: exchange_rates
#
#  id         :bigint           not null, primary key
#  currency   :string           not null
#  date       :date             not null
#  fetched_at :datetime         not null
#  rate       :decimal(10, 4)   not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Caches official ECB daily reference rates and converts any ECB-quoted
# source currency to USD through the EUR cross-rate for a given date. USD
# passes through unchanged; a date with no exact rate uses the latest
# earlier published rate.
class ExchangeRate < ApplicationRecord
  validates_db_uniqueness_of :date, scope: :currency

  def self.usd_amount(amount, currency:, date:)
    amount = amount.to_d
    return amount if currency == "USD"

    usd_rate = rate_on(currency: "USD", date:)
    return (amount * usd_rate).round(2) if currency == "EUR"

    (amount / rate_on(currency:, date:) * usd_rate).round(2)
  end

  def self.rate_on(currency:, date:)
    ensure_cached!

    where(currency:).where(date: ..date).order(date: :desc).pick(:rate) ||
      median_rate_for_missing_history(currency:) ||
      raise(ArgumentError, "No ECB reference rate cached for #{currency} on or before #{date}")
  end

  # Falls back to the median of a currency's cached rates within a three-month
  # window centered on its nearest available (earliest) cached date, when no
  # rate exists on or before the requested date. Returns nil when the currency
  # has no cached rate at any date, so `rate_on` raises as before.
  def self.median_rate_for_missing_history(currency:)
    earliest_date = where(currency:).minimum(:date)
    return nil unless earliest_date

    rates = where(currency:, date: (earliest_date - 3.months)..(earliest_date + 3.months)).order(:rate).pluck(:rate)
    middle = rates.length / 2
    rates.length.odd? ? rates[middle] : (rates[middle - 1] + rates[middle]) / 2
  end

  def self.ensure_cached!
    return if exists?

    rows = Ecb::ExchangeRatesClient.new.fetch_all
    fetched_at = Time.current
    insert_all(rows.map { |row| row.merge(fetched_at:) }) # rubocop:disable Rails/SkipsModelValidations -- one-time bulk cache of ECB's full history; per-row validation would be too slow for thousands of rows
  end
end
