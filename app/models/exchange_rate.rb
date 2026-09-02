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
class ExchangeRate < ApplicationRecord
  REFRESH_INTERVAL = 24.hours

  Conversion = Data.define(:order_date, :effective_date, :rate) do
    def usd_amount(amount)
      (amount.to_d * rate).round(2)
    end
  end

  validates_db_uniqueness_of :date, scope: :currency

  def self.usd_amount(amount, currency:, date:)
    amount = amount.to_d
    return amount if currency == "USD"

    usd_rate = rate_on(currency: "USD", date:)
    return (amount * usd_rate).round(2) if currency == "EUR"

    (amount / rate_on(currency:, date:) * usd_rate).round(2)
  end

  def self.eur_to_usd_conversion(date:)
    ensure_recent!

    effective_date, rate = where(currency: "USD").where(date: ..date).order(date: :desc).pick(:date, :rate)
    raise ArgumentError, "No ECB EUR-to-USD rate cached on or before #{date}" unless rate

    Conversion.new(order_date: date, effective_date:, rate:)
  end

  def self.rate_on(currency:, date:)
    ensure_cached!

    where(currency:).where(date: ..date).order(date: :desc).pick(:rate) ||
      median_rate_for_missing_history(currency:) ||
      raise(ArgumentError, "No ECB reference rate cached for #{currency} on or before #{date}")
  end

  def self.median_rate_for_missing_history(currency:)
    earliest_date = where(currency:).minimum(:date)
    return nil unless earliest_date

    rates = where(currency:, date: (earliest_date - 3.months)..(earliest_date + 3.months)).order(:rate).pluck(:rate)
    middle = rates.length / 2
    rates.length.odd? ? rates[middle] : (rates[middle - 1] + rates[middle]) / 2
  end

  def self.ensure_cached!
    return if exists?

    refresh!(Ecb::ExchangeRatesClient.new.fetch_all)
  end

  def self.ensure_recent!
    return ensure_cached! unless exists?
    return if maximum(:fetched_at) > REFRESH_INTERVAL.ago

    refresh!(Ecb::ExchangeRatesClient.new.fetch_recent)
  end

  def self.refresh!(rows)
    fetched_at = Time.current
    upsert_all(rows.map { |row| row.merge(fetched_at:) }, unique_by: %i[currency date]) # rubocop:disable Rails/SkipsModelValidations -- bulk ECB cache refresh; per-row validation would be too slow for thousands of rows
  end
end
